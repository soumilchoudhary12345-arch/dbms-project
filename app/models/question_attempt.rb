class QuestionAttempt < ApplicationRecord
  belongs_to :quiz_session
  belongs_to :question

  validates :question_id, uniqueness: { scope: :quiz_session_id }

  # Mistake book: wrong/skipped answers in finished sessions for this user.
  scope :missed, -> {
    joins(:quiz_session)
      .where(quiz_sessions: { status: QuizSession::SUBMITTED })
      .where(correct: false)
  }
  scope :missed_by, ->(user) { missed.where(quiz_sessions: { user_id: user.id }) }

  def grade!(given_answer)
    self.answer = given_answer.presence
    self.correct = answer.present? && answer == question.answer
    save!
  end

  def skipped?
    correct == false && answer.blank?
  end

  def resolved?
    resolved_at.present?
  end
end
