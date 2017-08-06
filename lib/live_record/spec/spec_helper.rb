require 'bundler'

Bundler.require :default, :test

require 'live_record'
require 'action_cable/engine'

Combustion.initialize! :all

require 'rspec/rails'
require 'capybara/rails'
require 'factory_girl_rails'
# require 'capybara/poltergeist'
