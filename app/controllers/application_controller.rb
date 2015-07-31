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

  def require_repo_permissions
    unless authorized_for_repo?(@repo)
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def authorized_for_repo?(repo)
    user_repos.any? do |user_repo_api_resp|
      user_repo = Repo.initialize_by_api(user_repo_api_resp)
      repo == user_repo
    end
  end

  def require_session
    unless logged_in?
      flash[:error] ||= []
      flash[:error] << "Please log in"
      redirect_to signin_auth_path
    end
  end

  def user_repos
    Rails.cache.fetch(user_repos_key, expires_in: 24.hours) do
      GitApi.new(current_user).repos
    end
  end

  def user_repos_key
    "user_repos_#{current_user.slug}"
  end

  def load_repo
    if params[:id]
      @repo = Repo.find(params[:id])
    else
      @repo = Repo.find_by!(
        :service => params[:service],
        :organization => params[:organization],
        :name => params[:name]
      )
    end
  end

  def load_build
    if params[:id]
      @build = Build.find(params[:id])
      @repo = @build.repo
    end
  end

  def redirect_with_error(path, error)
    flash[:error] ||= []
    flash[:error] << error
    redirect_to path
  end

  def render_422
    render json: {error: 422}, status: 422
  end
end
