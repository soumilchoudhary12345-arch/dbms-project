class Question < ApplicationRecord
  has_many :question_attempts, dependent: :destroy

  validates :body, presence: true
  validates :q_type, inclusion: { in: %w[mcq numeric assertion_reason subjective] }

  def options_hash
    options.present? ? JSON.parse(options) : {}
  end

  def correct?(given)
    given.present? && given == answer
  end
end
