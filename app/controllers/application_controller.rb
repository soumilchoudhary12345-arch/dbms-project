class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_user
  before_action :enforce_session_lock

  helper_method :current_user

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_user
    redirect_to signin_path unless current_user
  end

  # Once a quiz session is running the user cannot browse anywhere else —
  # every request (nav links, back button, direct URLs) is bounced back to
  # the active session. Submitting it is the only way out.
  def enforce_session_lock
    return if current_user.nil?
    return if controller_name == "sessions" && %w[show submit result].include?(action_name)
    return if controller_name == "auth" && action_name == "destroy"

    active = QuizSession.in_progress.where(user: current_user).order(created_at: :desc).first
    return unless active

    redirect_to session_path(active), alert: "Finish your practice session before moving on."
  end
end
