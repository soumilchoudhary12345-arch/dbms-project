class User < ApplicationRecord
  has_many :quiz_sessions, dependent: :nullify

  validates :email, presence: true, uniqueness: true

  PROVIDERS = %w[google apple facebook microsoft].freeze

  def self.sign_in_with(provider)
    email = "#{provider}@demo.local"
    find_or_create_by!(email: email) do |user|
      user.name = provider.capitalize
      user.provider = provider
    end
  end
end
