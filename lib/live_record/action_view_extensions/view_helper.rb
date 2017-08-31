# class ModuleWithParams < Module
#   def initialize(params)
#     params.each do |key, value|
#       instance_variable_set(key, value)
#     end
#   end

#   def included(base)
#     num = @num

#     base.class_eval do
#       num.times do |i|
#         attr_accessor "asset_#{i}"
#       end
#     end
#   end
# end

class LiveRecord::SyncBlock
  @tracked_records = {}

  class << self
    attr_accessor :tracked_records

    def add_to_tracked_records(object_id, attribute_name)
      @tracked_records[Thread.current.object_id][object_id] ||= []
      @tracked_records[Thread.current.object_id][object_id] << attribute_name
    end

    def reset_tracked_records
      @tracked_records.delete Thread.current.object_id
    end
  end

  def initialize(block)
    @block = block
  end

  def call_block_and_track_records
    start_tracking
    puts self.class.tracked_records
    @block.call
    puts self.class.tracked_records
    stop_tracking
  end

  module ApplicationRecordExtensions
    def _read_attribute(attribute_name)
      if ::LiveRecord::SyncBlock.tracked_records[Thread.current.object_id] && self.is_a?(ApplicationRecord)
        ::LiveRecord::SyncBlock.add_to_tracked_records(self.object_id, attribute_name)
      end
      super
    end
  end

  private

  def start_tracking
    self.class.tracked_records[Thread.current.object_id] = {}
  end

  def stop_tracking
    self.class.tracked_records.delete Thread.current.object_id
  end
end

# module SomeModule
#   def _read_attribute(attribute_name)
#     puts '!!!'
#     super
#   end

#   def read_attribute(attr_name)
#     puts 'RRRR'
#     super
#   end
# end

# ActiveRecord::AttributeMethods::Read.class_eval do
#   prepend LiveRecord::SyncBlock::ApplicationRecordExtensions
# end

# class LiveRecord::SyncBlock
#   attr_accessor :tracked_records

#   def initialize(block)
#     @block = block
#   end

#   # module ApplicationRecordExtensions
#   #   protected def _read_attribute(attribute_name)
#   #     @tracked_records[self] ||= []
#   #     @tracked_records[self] << attribute_name
#   #     super
#   #   end
#   # end

#   private

#   def start_tracking
#     tracked_records = @tracked_records

#     application_record_extensions = Module.new do
#       protected def _read_attribute(attribute_name)
#         # byebug
#         tracked_records[self] ||= []
#         tracked_records[self] << attribute_name
#         super
#       end
#     end

#     application_record_extensions.class_eval do
#       def       
#     end

#     ApplicationRecord.class_eval do
#       prepend application_record_extensions
#       # prepend Module.new do
#       #   protected def _read_attribute(attribute_name)
#       #     byebug
#       #     @tracked_records[self] ||= []
#       #     @tracked_records[self] << attribute_name
#       #     super
#       #   end
#       # end
#     end
#   end

#   def stop_tracking
#   end
# end

module LiveRecord
  module ActionViewExtensions
    module ViewHelper
      def live_record_element(record)
        raw " data-live-record-element='#{record.class.name}-#{record.id}' "
      end

      def live_record_updatable(record, attribute)
        raise ArgumentError, "[#{record.class}] does not have an attribute named [#{attribute}]" unless record.attribute_names.include? attribute.to_s
        raw " data-live-record-update-from='#{record.class.name}-#{record.id}-#{attribute}' "
      end

      def live_record_destroyable(record)
        raw " data-live-record-destroy-from='#{record.class.name}-#{record.id}' "
      end

      def live_record_sync(&block)
        # ActiveRecord::Attribute.class_eval do
        #   define_method(:value) do
        #     byebug
        #   end
        # end

        # ApplicationRecord.descendants.each do |klass|
        #   klass.class_eval do
        #     attribute_names.each do |attribute_name|
        #       define_method(attribute_name) do
        #         called_records_attributes[self] ||= []
        #         called_records_attributes[self] << attribute_name
        #         self[attribute_name]
        #       end
        #     end
        #   end
        # end

        # ApplicationRecord.class_eval do
        #   prepend SomeModule # LiveRecord::SyncBlock::ApplicationRecordExtensions
        # end



        # ApplicationRecord.class_eval do
        #   prepend
        #   define_method(:title) do
        #     puts '!!!'
        #     byebug
        #   end

        #   define_method(:method_missing) do
        #     puts 'EEE'
        #     byebug
        #   end
        # end

        sync_block = LiveRecord::SyncBlock.new(block)
        sync_block.call_block_and_track_records

        # block.call

        # byebug

        # byebug

        # Post.first.title

        # block.call

        # byebug
      end
    end
  end
end

ActiveSupport.on_load(:action_view) do
  include LiveRecord::ActionViewExtensions::ViewHelper
end

ActiveSupport.on_load(:active_record) do
  # ActiveRecord::AttributeMethods::Read.class_eval do
  prepend LiveRecord::SyncBlock::ApplicationRecordExtensions
  # end
  # ApplicationRecord.class_eval do
  #   prepend LiveRecord::SyncBlock::ApplicationRecordExtensions
  # end
end