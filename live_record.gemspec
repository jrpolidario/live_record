lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'live_record/version'

Gem::Specification.new do |s|
  s.name        = 'live_record'
  s.version     = LiveRecord::VERSION
  s.date        = '2017-08-03'
  s.summary     = 'Rails 5 ActionCable Live JS Objects and DOM Elements'
  s.description = "Auto-syncs records in client-side JS (through a Model DSL) from changes in the backend Rails server through ActionCable.\nAuto-updates DOM elements mapped to a record attribute, from changes.\nAutomatically resyncs after client-side reconnection."
  s.authors     = ['Jules Roman B. Polidario']
  s.email       = 'jrpolidario@gmail.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/jrpolidario/live_record'
  s.license     = 'MIT'
  s.required_ruby_version = '~> 2.0'

  s.add_dependency 'rails', '~> 5.0', '< 5.2'
end