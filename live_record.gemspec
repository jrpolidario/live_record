lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'live_record/version'

Gem::Specification.new do |s|
  s.name        = 'live_record'
  s.version     = LiveRecord::VERSION
  s.summary     = 'Rails 5 ActionCable Live JS Objects and DOM Elements'
  s.description = "Auto-syncs records in client-side JS (through a Model DSL) from changes (updates/destroy) in the backend Rails server through ActionCable.\n Also supports streaming newly created records to client-side JS.\n Supports lost connection restreaming for both new records (create), and record-changes (updates/destroy).\n Auto-updates DOM elements mapped to a record attribute, from changes (updates/destroy)."
  s.authors     = ['Jules Roman B. Polidario']
  s.email       = 'jrpolidario@gmail.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/jrpolidario/live_record'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.2.2'

  s.add_dependency 'rails', '~> 5.0'

  s.add_development_dependency 'rails', '~> 5.2'
  s.add_development_dependency 'puma', '~> 3.10'
  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'byebug', '~> 9.0'

  s.add_development_dependency 'sprockets-rails', '~> 3.2'
  s.add_development_dependency 'sprockets-export', '~> 1.0'
  s.add_development_dependency 'coffee-rails', '~> 4.2'
  s.add_development_dependency 'jquery-rails', '~> 4.3'
  s.add_development_dependency 'jbuilder', '~> 2.7'
  s.add_development_dependency 'blade', '~> 0.7'

  s.add_development_dependency 'sqlite3', '~> 1.3'
  s.add_development_dependency 'redis', '~> 3.3'

  s.add_development_dependency 'rspec-rails', '~> 3.6'
  s.add_development_dependency 'combustion', '~> 0.9'
  s.add_development_dependency 'chromedriver-helper', '~> 1.2'
  s.add_development_dependency 'selenium-webdriver', '~> 3.12'
  s.add_development_dependency 'faker', '~> 1.8'
  s.add_development_dependency 'database_cleaner', '~> 1.6'
  s.add_development_dependency 'timecop', '0.9'
end
