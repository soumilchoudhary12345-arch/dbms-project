class QuestionAttempt < ApplicationRecord
  belongs_to :quiz_session
  belongs_to :question

  def grade!(given_answer)
    self.answer = given_answer.presence
    self.correct = answer.present? && answer == question.answer
    save!
  end
end
