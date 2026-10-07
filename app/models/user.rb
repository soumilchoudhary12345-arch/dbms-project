class User < ApplicationRecord
  has_many :quiz_sessions, dependent: :nullify
  has_many :todos, dependent: :destroy

  # The DB stores and indexes email lowercased (UNIQUE index on users.email).
  before_validation :normalize_email
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  PROVIDERS = %w[demo google_oauth2 microsoft_graph facebook apple].freeze

  def self.sign_in_with(provider)
    email = "#{provider}@demo.local"
    find_or_create_by!(email: email) do |user|
      user.name = provider.capitalize
      user.provider = provider
    end
  end

  # Identity for real OAuth: provider + uid is the durable key; email links
  # the same person if they come back through a different provider.
  def self.from_omniauth(auth)
    provider = auth.provider.to_s
    uid = auth.uid.to_s
    info = auth.info

    user = find_by(provider: provider, uid: uid)
    return user if user

    email = info.email.to_s.strip.downcase
    if email.present? && (linked = find_by(email: email))
      linked.update(provider: provider, uid: uid)
      linked.update(name: info.name) if linked.name.blank? && info.name.present?
      return linked
    end

    create!(
      provider: provider,
      uid: uid,
      name: info.name.presence || email.split("@").first || provider.split("_").first.capitalize,
      email: email.presence || "#{uid}@#{provider}.oauth.local"
    )
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
