# Real OAuth via OmniAuth.
#
# Each strategy registers only when its credentials exist in the environment,
# so the app boots before anything is configured: an unconfigured provider's
# button falls through to AuthController#create, which explains what to set.
# Copy .env.example to .env and fill in the provider you want to use.

OmniAuth.config.allowed_request_methods = %i[post]

Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
    provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"],
             scope: "email,profile", prompt: "select_account"
  end

  if ENV["MICROSOFT_CLIENT_ID"].present? && ENV["MICROSOFT_CLIENT_SECRET"].present?
    provider :microsoft_graph, ENV["MICROSOFT_CLIENT_ID"], ENV["MICROSOFT_CLIENT_SECRET"]
  end

  if ENV["FACEBOOK_APP_ID"].present? && ENV["FACEBOOK_APP_SECRET"].present?
    provider :facebook, ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_APP_SECRET"], scope: "email"
  end
end
