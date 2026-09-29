class AuthController < ApplicationController
  skip_before_action :require_user, only: %i[new create]

  def new
    redirect_to root_path if current_user
  end

  def create
    provider = params[:provider].to_s
    unless User::PROVIDERS.include?(provider)
      redirect_to signin_path and return
    end

    user = User.sign_in_with(provider)
    session[:user_id] = user.id
    redirect_to root_path
  end

  def destroy
    session.delete(:user_id)
    redirect_to signin_path
  end
end
