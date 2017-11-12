module LiveRecord
  module Model
    module Callbacks
      extend ActiveSupport::Concern

      included do
        after_update_commit :__live_record_dereference_changed_attributes__
        before_update :__live_record_reference_changed_attributes__
        after_update_commit :__live_record_broadcast_record_update__
        after_destroy_commit :__live_record_broadcast_record_destroy__
        after_create_commit :__live_record_broadcast_record_create__
        after_commit :__live_record_broadcast_record_autoload__,  on: [:update, :create]

        def self.live_record_whitelisted_attributes(record, current_user)
          []
        end

        private

        def __live_record_reference_changed_attributes__
          @_live_record_changed_attributes = changed
        end

        def __live_record_dereference_changed_attributes__
          @_live_record_changed_attributes = nil
        end

        def __live_record_broadcast_record_update__
          included_attributes = attributes.slice(*@_live_record_changed_attributes)
          message_data = { 'action' => 'update', 'attributes' => included_attributes }
          LiveRecord::ChangesChannel.broadcast_to(self, message_data)
          LiveRecordUpdate.create!(recordable_type: self.class, recordable_id: self.id, created_at: DateTime.now)
        end

        def __live_record_broadcast_record_destroy__
          message_data = { 'action' => 'destroy' }
          LiveRecord::ChangesChannel.broadcast_to(self, message_data)
        end

        def __live_record_broadcast_record_create__
          message_data = { 'action' => 'create', 'attributes' => attributes }
          ActionCable.server.broadcast "live_record:publications:#{self.class.name.underscore}", message_data
        end

        def __live_record_broadcast_record_autoload__
          included_attributes = nil

          changed_attributes = attributes.slice(*@_live_record_changed_attributes)

          # if after_update
          if changed_attributes.present?
            included_attributes = changed_attributes
          # else if after_create_commit
          else
            included_attributes = attributes
          end

          message_data = {
            'action' => 'create_or_update',
            'model_name' => self.class.to_s,
            'record_id' => id,
            'attributes' => included_attributes
          }
          ActionCable.server.broadcast 'live_record:autoloads', message_data
        end
      end
    end
  end
end
