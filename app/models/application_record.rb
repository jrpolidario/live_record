class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  has_many :live_record_updates, as: :recordable

  after_update :__live_record_reference_changed_attributes__
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
    @_live_record_changed_attributes= nil
    message_data = { 'action' => 'update', 'attributes' => included_attributes }
    LiveRecordChannel.broadcast_to(self, message_data)
    LiveRecordUpdate.create!(recordable: self)
  end

  def __live_record_broadcast_record_destroy__
    message_data = { 'action' => 'destroy' }
    LiveRecordChannel.broadcast_to(self, message_data)
  end
end
