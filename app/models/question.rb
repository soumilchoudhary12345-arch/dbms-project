class Question < ApplicationRecord
  has_many :question_attempts, dependent: :destroy

  Q_TYPES = %w[mcq short long].freeze
  DIFFICULTIES = %w[easy medium hard].freeze

  validates :body, presence: true
  validates :q_type, inclusion: { in: Q_TYPES }
  validates :difficulty, inclusion: { in: DIFFICULTIES }, allow_nil: true
  validates :marks, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def options_hash
    return {} if options.blank?
    return options if options.is_a?(Hash)

    JSON.parse(options)
  rescue JSON::ParserError
    {}
  end

  def correct?(given)
    given.present? && given == answer
  end
end
