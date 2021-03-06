Rails.application.routes.draw do
  root 'home#index'

  resource :auth, only: [] do
    get :signin,  action: :new
    get :signout, action: :destroy
    get ':provider/callback', action: :create, as: :callback
  end

  resources :repos, constraints: { name: /[^\/]+/}, only: [:new, :create, :show] do
    collection do
      get ':service/:organization/:name', to: 'repos#show', as: 'long'
      get ':service/:organization/:name/:id', to: 'builds#show', as: 'build'

      post ':service/:organization/:name/webhook', to: 'repos#webhook', as: 'webhook'
      post ':service/:organization/:name/follow', to: 'repos#follow', as: 'follow'
      post ':service/:organization/:name/unfollow', to: 'repos#unfollow', as: 'unfollow'
      post ':service/:organization/:name/build', to: 'repos#build', as: 'build_head'
    end
  end

  resources :builds, only: [:show]
  resources :users, only: [:show] do
    collection do
      post :sync, to: 'users#sync'
    end
  end
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
