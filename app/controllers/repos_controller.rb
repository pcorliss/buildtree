class ReposController < ApplicationController
  before_filter :require_session

  def new
    @user_repos = user_repos
    render :json => @user_repos
  end
end
