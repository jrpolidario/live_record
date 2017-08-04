require 'bundler'

Bundler.require :default, :test

Combustion.initialize! :all

require 'rspec/rails'
require 'capybara/rails'
require 'factory_girl_rails'

require 'live_record'