class HomeController < ApplicationController
  before_filter :require_session, only: [:index]

  def index
    redirect_to user_path(current_user)
  end
end
