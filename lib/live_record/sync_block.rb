class LiveRecord::SyncBlock
  Thread.current['live_record.current_tracked_records'] = {}

  attr_accessor :tracked_records

  class << self
    def add_to_tracked_records(record, attribute_name)
      Thread.current['live_record.current_tracked_records'][{model: record.class.name.to_sym, record_id: record.id}] ||=  []
      Thread.current['live_record.current_tracked_records'][{model: record.class.name.to_sym, record_id: record.id}] << attribute_name
    end
  end

  def initialize(block)
    @block = block
  end

  def call_block_and_track_records
    start_tracking
    @block_evaluated_value = @block.call
    @tracked_records = Thread.current['live_record.current_tracked_records']
    puts @tracked_records
    stop_tracking
  end

  def to_s
    @block_evaluated_value
  end

  module ActiveRecordExtensions
    def _read_attribute(attribute_name)
      if Thread.current['live_record.current_tracked_records'] && !Thread.current['live_record.is_tracking_locked'] && self.class < ApplicationRecord
        Thread.current['live_record.is_tracking_locked'] = true
        ::LiveRecord::SyncBlock.add_to_tracked_records(self, attribute_name)
        Thread.current['live_record.is_tracking_locked'] = false
      end
      super(attribute_name)
    end
  end

  module Helpers
    def live_record_sync(&block)
      sync_block = LiveRecord::SyncBlock.new(block)
      sync_block.call_block_and_track_records
      sync_block
    end
  end

  private

  def start_tracking
    Thread.current['live_record.current_tracked_records'] = {}
  end

  def stop_tracking
    Thread.current['live_record.current_tracked_records'] = nil
  end
end

ActiveSupport.on_load(:active_record) do
  prepend LiveRecord::SyncBlock::ActiveRecordExtensions
end

ActiveSupport.on_load(:action_view) do
  include LiveRecord::SyncBlock::Helpers
end

ActiveSupport.on_load(:action_controller) do
  include LiveRecord::SyncBlock::Helpers
end