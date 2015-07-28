class UsersController < ApplicationController
  before_filter :require_session, only: [:show]

  def show
    render json: {}
  end
end
