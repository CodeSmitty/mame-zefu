source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.7"

gem "administrate"
gem "bootsnap", require: false
gem "clearance"
gem "down", "~> 5.0"
gem "fractional"
gem "importmap-rails"
gem 'ingreedy', '~> 0.1.0'
gem "jbuilder"
gem "measured"
gem "net_tcp_client"
gem "parser", "~> 3.3.7.0"
gem "pg", "~> 1.1"
gem "puma", "< 7"
gem "pundit", "~> 2.5"
gem "rails", "~> 7.2.0"
gem "rails_semantic_logger"
gem "sprockets-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.0"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem 'erb_lint'
  gem 'factory_bot_rails'
  gem 'pundit-matchers', '~> 4.0'
  gem 'pry'
  gem 'rspec-rails', '~> 7.1.0'
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'shoulda-matchers', '~> 6.0'
end

group :development do
  gem "web-console"
  gem "bundler-audit"
end

group :test do
  gem "capybara"
  gem "rspec-github", require: false
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "simplecov-cobertura", require: false
  gem "webmock"
end
