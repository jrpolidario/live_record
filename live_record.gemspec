lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'live_record/version'

Gem::Specification.new do |s|
  s.name        = 'live_record'
  s.version     = LiveRecord::VERSION
  s.date        = '2017-08-01'
  s.summary     = 'Rails 5 ActionCable Live JS Objects and DOM Elements'
  s.description = 'Rails 5 ActionCable Live JS Objects and DOM Elements'
  s.authors     = ['Jules Roman B. Polidario']
  s.email       = 'jrpolidario@gmail.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/jrpolidario/live_record'
  s.license     = 'MIT'
  s.required_ruby_version = '~> 2.0'

  s.add_dependency 'rails', '~> 5.0', '< 5.2'
  s.add_development_dependency 'byebug', '~> 9.0'
end