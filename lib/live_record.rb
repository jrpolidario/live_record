require 'rails'
require 'rails/generators'
require 'active_support/concern'

Dir[__dir__ + '/live_record/*.rb'].each {|file| require file }
Dir[__dir__ + '/live_record/model/*.rb'].each {|file| require file }
Dir[__dir__ + '/live_record/channel/*.rb'].each {|file| require file }
Dir[__dir__ + '/live_record/generators/*.rb'].each {|file| require file }

module LiveRecord
end