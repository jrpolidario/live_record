# require 'active_record'
# require 'byebug'

# module ActiveRecord::Scoping::Named
#   # module SomeModule
#   #   def scope(name, options)
#   #   	byebug
#   #     super
#   #   end
#   # end
#   # include SomeModule
#   # def scope(name, options)
#   #   super
#   # end

#   # def scope(name, options)
#   #   byebug
#   #   # super
#   # end

#   extend ActiveSupport::Concern

#   included do 
#     @live_record_scopes = []

#     def self.scope(name, body, &block)
#       @live_record_scopes << name
#       super
#     end
#   end
# end
