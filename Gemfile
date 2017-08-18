source 'https://rubygems.org'

gemspec

group :development, :test do
  # issues with Combustion + FactoryGirl factory loading: https://github.com/pat/combustion/issues/33
  # therefore, this gem should not be part of .gemspec but instead is specified here in the Gemfile
  gem 'factory_girl_rails', require: false
end