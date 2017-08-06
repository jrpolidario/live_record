require 'bundler'

Bundler.require :default, :test

require 'live_record'
require 'action_cable/engine'

Combustion.initialize! :all

run Combustion::Application
