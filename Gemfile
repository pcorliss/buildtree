source 'https://rubygems.org'


gem 'rails', '~> 4.2.3'
gem 'pg', '~> 0.18.2'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'jbuilder', '~> 2.0'

gem 'omniauth', '~> 1.3.1'
gem 'omniauth-oauth2', '~> 1.1.2'
gem 'omniauth-github', '~> 1.1.2'
gem 'octokit', '~> 4.0.1'
gem 'sshkey', '~> 1.7.0'

gem 'haml', '~> 4.0.6'
gem 'sass-rails'
gem 'less-rails'
gem 'therubyracer'
gem 'twitter-bootswatch-rails', '~> 3.1.1'
gem 'font-awesome-rails'
gem 'uglifier', '>= 1.3.0'

gem 'delayed_job_active_record', '~> 4.0.3'
gem 'daemons', '~> 1.2.3'

gem 'nokogiri', '~> 1.8.1'

group :development do
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard-rspec'
end

# run `bundle install --without darwin` for non-macs
group :development, :darwin do
  gem 'rb-fsevent'
end

group :development, :test do
  gem 'byebug'
  gem 'web-console', '~> 2.0'
  gem 'dotenv-rails'
  gem 'factory_girl_rails'
  gem 'pry-rails'
  gem 'rspec-rails'
end

group :test do
  gem 'rake', '~> 10.4.2'
  gem 'webmock'
  gem 'simplecov', :require => false
end

group :production do
  gem 'rails_12factor'
end

