source 'https://rubygems.org'

gemspec

group :development, :test do
  # issues with Combustion + FactoryGirl factory loading: https://github.com/pat/combustion/issues/33
  # therefore, this gem should not be part of .gemspec but instead is specified here in the Gemfile
  gem 'factory_girl_rails', '~> 4.8', require: false
  # do not require to prevent Capybara deprecation warning on rspec run
  gem 'capybara', '~> 3.1', require: false

  gem 'sprockets-export', '~> 1.0.0', require: false
end
