class QuizSession < ApplicationRecord
  belongs_to :user, optional: true
  has_many :question_attempts, dependent: :destroy

  STATUSES = %w[active finished].freeze

  SECONDS_PER_DIFFICULTY = { "easy" => 60, "medium" => 90, "hard" => 120, "super_hard" => 150 }.freeze

  validates :status, inclusion: { in: STATUSES }

  def active?
    status == "active"
  end

  def finished?
    status == "finished"
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

  def self.build_session(level: "medium", user: nil)
    picked = pick_for_level(level)
    limit = picked.sum { |q| SECONDS_PER_DIFFICULTY.fetch(q.difficulty, 90) }

    transaction do
      session = create!(user: user, status: "active", time_limit_seconds: limit,
                        difficulty_mix: JSON.generate(picked.group_by(&:difficulty).transform_values(&:size)))
      picked.each { |q| session.question_attempts.create!(question: q, correct: false) }
      session
    end
  end

  def self.pick_for_level(level)
    counts =
      case level
      when "easy"    then { "easy" => 4, "medium" => 4, "hard" => 2 }
      when "hard"    then { "medium" => 2, "hard" => 4, "super_hard" => 4 }
      else                { "medium" => 4, "hard" => 6 }
      end

    counts.flat_map do |difficulty, n|
      Question.where(difficulty: difficulty).order("RANDOM()").limit(n).to_a
    end.uniq.tap do |picked|
      if picked.size < 10
        picked.concat(Question.where.not(id: picked.map(&:id)).order("RANDOM()")
                              .limit(10 - picked.size).to_a)
      end
    end.first(10)
  end
end
