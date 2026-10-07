class AuthController < ApplicationController
  skip_before_action :require_user, only: %i[new create callback failure]

  FRIENDLY = {
    "google_oauth2" => "Google",
    "microsoft_graph" => "Microsoft",
    "facebook" => "Facebook",
    "apple" => "Apple",
    "google" => "Google",
    "microsoft" => "Microsoft"
  }.freeze

  ENV_KEYS = {
    "google_oauth2" => "GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET",
    "microsoft_graph" => "MICROSOFT_CLIENT_ID and MICROSOFT_CLIENT_SECRET",
    "facebook" => "FACEBOOK_APP_ID and FACEBOOK_APP_SECRET"
  }.freeze

  def new
    redirect_to root_path if current_user
  end

  # Reached when a provider has no OmniAuth strategy registered (missing
  # credentials) or for the local demo account.
  def create
    provider = params[:provider].to_s

    if provider == "demo"
      session[:user_id] = User.sign_in_with("demo").id
      redirect_to root_path
      return
    end

    name = FRIENDLY.fetch(provider, provider.capitalize)
    hint =
      if ENV_KEYS.key?(provider)
        "Set #{ENV_KEYS[provider]} in .env (copy .env.example)."
      else
        "Apple sign-in needs an Apple Developer account; wire omniauth-apple later."
      end
    redirect_to signin_path, alert: "#{name} sign-in isn't configured yet. #{hint}"
  end

  # OmniAuth hands the verified auth hash over here after the provider redirects.
  def callback
    auth = request.env["omniauth.auth"]
    raise "missing auth hash" if auth.blank?

    session[:user_id] = User.from_omniauth(auth).id
    redirect_to root_path
  rescue StandardError => e
    Rails.logger.warn("OAuth callback failed: #{e.class}: #{e.message}")
    redirect_to signin_path, alert: "Sign-in with #{FRIENDLY[params[:provider]] || params[:provider]} failed. Try again."
  end

  def failure
    redirect_to signin_path, alert: "Sign-in failed (#{params[:message]}). Try again."
  end

  def destroy
    session.delete(:user_id)
    redirect_to signin_path
  end
end
