source "https://rubygems.org"
ruby "3.4.4"

gem "pg"
gem "rails", "~> 8.0.0"

gem "apipie-rails"
gem "aws-sdk-s3"
gem "browser"
gem "cancancan"
gem "country_select"
gem "dalli"
gem "devise"
gem "devise-encryptable"
gem "dotenv"
gem "exception_notification"
gem "geocoder"
gem "haml-rails"
gem "has_scope"
gem "image_processing"
gem "kaminari"
gem "maxminddb"
gem "pagy"
gem "paper_trail"
gem "paper_trail-association_tracking"
gem "phonelib"
gem "puma"
gem "rack"
gem "rack-attack"
gem "rails_admin"
gem "rails_autolink"
gem "rake"
gem "sanitize"
gem "sassc-rails"
gem "scout_apm", git: "https://github.com/GabrielNagy/scout_apm_ruby.git", ref: "de4bc9375b99bd9bcdb17835df950e8be9073565"
gem "simple_token_authentication", git: "https://github.com/gonzalo-bulnes/simple_token_authentication.git", ref: "f1cba4e"
gem "solid_cache", "~> 1.0"
gem "solid_queue", "~> 1.1"
gem "sprockets-rails"
gem "strip_attributes"
gem "tzinfo-data"
gem "uglifier"
gem "webrick"

group :production, :development, :staging do
  gem "rails_semantic_logger"
end

group :test do
  gem "capybara"
  gem "capybara-screenshot"
  gem "factory_bot_rails"
  gem "launchy"
  gem "rails-controller-testing"
  gem "rspec-rails"
  gem "rspec-retry"
  gem "rubocop"
  gem "rubocop-performance", require: false
  gem "rubocop-rspec"
  gem "selenium-webdriver"
  gem "simplecov"
  gem "simplecov-cobertura"
  gem "spork"
  gem "timecop"
end

group :development, :test do
  gem "brakeman"
  gem "bullet"
  gem "bundler-audit"
  gem "database_cleaner"
  gem "debug", require: false
  gem "derailed_benchmarks"
  gem "email_spec"
  gem "listen"
  gem "ostruct" # suppress deprecation warning for pry
  gem "rubocop-rails-omakase", require: false
  gem "pry"
end
