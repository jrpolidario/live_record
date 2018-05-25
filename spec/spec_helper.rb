require 'bundler'

Bundler.require :default, :development

require 'live_record'
require 'action_cable/engine'

Combustion.initialize! :all do
  config.active_record.sqlite3.represent_boolean_as_integer = true
end

require 'rspec/rails'
require 'capybara/rails'
require 'factory_girl_rails'
