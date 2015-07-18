OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  scopes = "user:email,read:org,repo:status,repo_deployment,write:repo_hook,repo"
  provider :github,     ENV['GITHUB_KEY'],    ENV['GITHUB_SECRET'], scope: scopes
  #provider :bitbucket,  ENV['BITBUCKET_KEY'], ENV['BITBUCKET_SECRET']
end
