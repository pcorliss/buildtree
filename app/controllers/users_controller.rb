class UsersController < ApplicationController
  before_filter :require_session, only: [:show, :sync]

  def show
    if current_user.id == params[:id]
      @display_user = current_user
    else
      @display_user = User.find(params[:id])
    end

    # This really needs to be paginated
    @builds = Build.where(repo: @display_user.repos).order('id desc').includes(:repo)
  end

  def sync
    Rails.cache.delete(user_repos_key)
    user_repos
    redirect_to new_repo_path
  end
end
