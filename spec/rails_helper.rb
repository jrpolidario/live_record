ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
Dir[__dir__ + '/helpers/*.rb'].each {|file| require file }

ActiveRecord::Migration.maintain_test_schema!

Capybara.javascript_driver = :selenium_chrome_headless # :selenium_chrome 
Capybara.server = :puma

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Capybara::DSL
  config.include SpecHelpers::Wait

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
    DatabaseCleaner.strategy = :deletion
  end
  
  config.before(:each) do
    DatabaseCleaner.start
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end
end
