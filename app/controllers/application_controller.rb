class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :current_user

  def current_user
    @user ||= User.find(session[:user_id]) if session[:user_id]
  rescue StandardError
    nil
  end

  def logged_in?
    !!current_user
  end

  private

  #def authorized_for_repo?(repo)
    #user_repos.any? do |user_repo_api_resp|
      #user_repo = Repo.initialize_by_api(user_repo_api_resp)
      #repo.name == user_repo.name &&
      #repo.organization == user_repo.organization &&
      #repo.service == user_repo.service
    #end
  #end

  def require_session
    redirect_to signin_auth_path unless session[:user_id]
  end

  #def user_repos
    #Rails.cache.fetch("user_repos_#{current_user.slug}") do
      #GitApi.new(current_user).repos
    #end
  #end
end
