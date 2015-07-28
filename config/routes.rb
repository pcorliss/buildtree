Rails.application.routes.draw do
  root 'home#index'

  resource :auth, only: [] do
    get :signin,  action: :new
    get :signout, action: :destroy
    get ':provider/callback', action: :create, as: :callback
  end

  resources :repos, only: [:new, :create, :show] do
    collection do
      get ':service/:organization/:name', to: 'repos#show', as: 'long'
      post ':service/:organization/:name/webhook', to: 'repos#webhook', as: 'webhook'
      get ':service/:organization/:name/:id', to: 'builds#show', as: 'builds'
    end
  end

  resources :builds, only: [:show]
  resources :users, only: [:show]
end

Rails.application.routes.url_helpers.module_eval do
  def repo_path(repo, options = {})
    long_repos_path(
      repo[:service],
      repo[:organization],
      repo[:name],
      options
    )
  end

  def repo_url(repo, options = {})
    long_repos_url(
      repo[:service],
      repo[:organization],
      repo[:name],
      options
    )
  end
end
