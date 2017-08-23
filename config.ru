require 'bundler'

Bundler.require :default, :development

require 'live_record'
require 'action_cable/engine'

Combustion.initialize! :all

run Combustion::Application
