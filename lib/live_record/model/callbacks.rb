module LiveRecord
  module Model
    module Callbacks
      extend ActiveSupport::Concern

      included do
        before_update :__live_record_reference_changed_attributes__
        after_update_commit :__live_record_broadcast_record_update__
        after_destroy_commit :__live_record_broadcast_record_destroy__

        def self.live_record_whitelisted_attributes(record, current_user)
          []
        end

        private

        def __live_record_reference_changed_attributes__
          @_live_record_changed_attributes = changed
        end

        def __live_record_broadcast_record_update__
          included_attributes = attributes.slice(*@_live_record_changed_attributes)
          @_live_record_changed_attributes = nil
          message_data = { 'action' => 'update', 'attributes' => included_attributes }
          LiveRecordChannel.broadcast_to(self, message_data)
          LiveRecordUpdate.create!(recordable_type: self.class, recordable_id: self.id, created_at: DateTime.now)
        end

        def __live_record_broadcast_record_destroy__
          message_data = { 'action' => 'destroy' }
          LiveRecordChannel.broadcast_to(self, message_data)
        end
      end
    end
  end
end