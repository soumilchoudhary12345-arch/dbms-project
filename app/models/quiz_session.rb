class QuizSession < ApplicationRecord
  belongs_to :user, optional: true
  has_many :question_attempts, dependent: :destroy

  IN_PROGRESS = "in_progress"
  SUBMITTED = "submitted"
  STATUSES = [ IN_PROGRESS, SUBMITTED ].freeze

  SECONDS_PER_DIFFICULTY = { "easy" => 60, "medium" => 90, "hard" => 120 }.freeze

  scope :in_progress, -> { where(status: IN_PROGRESS) }
  scope :submitted, -> { where(status: SUBMITTED) }

  validates :status, inclusion: { in: STATUSES }

  def active?
    status == IN_PROGRESS
  end

  def finished?
    status == SUBMITTED
  end

  def questions
    Question.where(id: question_attempts.select(:question_id))
  end

  def time_remaining
    return 0 if finished?

    deadline = created_at + time_limit_seconds.seconds
    [ deadline - Time.current, 0 ].max.round
  end

  def expired?
    active? && time_remaining <= 0
  end

  # "4 easy · 4 medium · 2 hard" — wraps safely, unlike the raw JSON column.
  def mix_label
    counts = difficulty_mix.present? ? JSON.parse(difficulty_mix) : {}
    return "—" if counts.empty?

    counts.map { |difficulty, n| "#{n} #{difficulty.tr('_', ' ')}" }.join(" · ")
  rescue JSON::ParserError
    difficulty_mix.to_s
  end

  # Attempts start unanswered (answer/correct NULL); submit! fills them in.
  def self.build_session(level: "medium", user: nil)
    picked = pick_for_level(level)
    limit = picked.sum { |q| SECONDS_PER_DIFFICULTY.fetch(q.difficulty, 90) }

    transaction do
      session = create!(user: user, status: IN_PROGRESS, time_limit_seconds: limit,
                        total_questions: picked.size,
                        difficulty_mix: JSON.generate(picked.group_by(&:difficulty).transform_values(&:size)))
      picked.each { |q| session.question_attempts.create!(question: q) }
      session
    end
  end

  # One-question practice session, used by the mistake book's Retry.
  def self.build_retry(question, user: nil)
    transaction do
      session = create!(user: user, status: IN_PROGRESS,
                        time_limit_seconds: SECONDS_PER_DIFFICULTY.fetch(question.difficulty, 90),
                        total_questions: 1,
                        difficulty_mix: JSON.generate({ question.difficulty => 1 }))
      session.question_attempts.create!(question: question)
      session
    end
  end

  # Grades every attempt and stores the score in a single transaction.
  # +answers+ is a hash of question_id => chosen option (or controller params).
  def submit!(answers = {})
    given = answers.respond_to?(:to_unsafe_h) ? answers.to_unsafe_h : answers

    transaction do
      question_attempts.includes(:question).each do |attempt|
        attempt.grade!(given[attempt.question_id.to_s])
      end

      update!(status: SUBMITTED, submitted_at: Time.current,
              correct_count: question_attempts.where(correct: true).count)
    end
  end

  # Level picked from recent performance: last 5 finished sessions.
  def self.level_for(user)
    recent = submitted.where(user: user).order(submitted_at: :desc).limit(5)
    answered = QuestionAttempt.where(quiz_session: recent).count
    return "medium" if answered.zero?

    accuracy = recent.sum(:correct_count).to_f / answered
    return "easy" if accuracy < 0.5
    return "hard" if accuracy >= 0.8

    "medium"
  end

  def self.mix_counts_for(level)
    case level
    when "easy"    then { "easy" => 4, "medium" => 4, "hard" => 2 }
    when "hard"    then { "medium" => 2, "hard" => 8 }
    else                { "medium" => 4, "hard" => 6 }
    end
  end

  # Preview only: the real session picks questions (and its limit) at create time.
  def self.estimate_for(level)
    counts = mix_counts_for(level)
    { questions: counts.values.sum,
      seconds: counts.sum { |difficulty, n| n * SECONDS_PER_DIFFICULTY.fetch(difficulty, 90) } }
  end

  def self.pick_for_level(level)
    mix_counts_for(level).flat_map do |difficulty, n|
      Question.where(difficulty: difficulty).order("RANDOM()").limit(n).to_a
    end.uniq.tap do |picked|
      if picked.size < 10
        picked.concat(Question.where.not(id: picked.map(&:id)).order("RANDOM()")
                              .limit(10 - picked.size).to_a)
      end
    end.first(10)
  end
end
