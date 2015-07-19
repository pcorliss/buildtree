Rails.application.routes.draw do
  resource :auth, only: [] do
    get :signin,  action: :new
    get :signout, action: :destroy
    get ':provider/callback', action: :create, as: :callback
  end

  resources :repos, only: [:new, :create]
end
