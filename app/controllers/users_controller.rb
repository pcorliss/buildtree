class UsersController < ApplicationController
  before_filter :require_session, only: [:show]

  def show
    if current_user.id == params[:id]
      @display_user = current_user
    else
      @display_user = User.find(params[:id])
    end

    # This really needs to be paginated
    @builds = Build.where(repo: @display_user.repos).order('id desc').includes(:repo)
  end
end
