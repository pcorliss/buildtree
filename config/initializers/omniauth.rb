OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  github_options = {
    :scope => "user:email,read:org,repo:status,repo_deployment,write:repo_hook,repo"
  }

  if host = ENV['GHE_HOST']
    github_options[:client_options] = {
      :site => "https://#{host}/api/v3",
      :authorize_url => "https://#{host}/login/oauth/authorize",
      :token_url => "https://#{host}/login/oauth/access_token",
    }
  end

  provider :github,     ENV['GITHUB_KEY'],    ENV['GITHUB_SECRET'], github_options
  #provider :bitbucket,  ENV['BITBUCKET_KEY'], ENV['BITBUCKET_SECRET']
end
