class AuthsController < ApplicationController
  def new
    if current_user
      flash.now[:warning] ||= []
      flash.now[:warning] << "You are already logged in."
    end
  end

  def create
    @user = User.find_or_create_from_auth_hash(auth_hash)
    if @user.valid?
      session[:user_id] = @user.id
      flash[:success] ||= []
      flash[:success] << 'Signed In'
      redirect_to user_path(@user)
    else
      flash[:error] ||= []
      flash[:error] << "Unable to login with #{params[:provider]}"
      redirect_to signin_auth_path
    end
  end

  def destroy
    reset_session
    flash[:success] ||= []
    flash[:success] << 'You have successfully logged out.'
    redirect_to signin_auth_path
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
