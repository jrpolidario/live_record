class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  has_many :live_record_updates, as: :recordable

  after_update :__broadcast_record_update__
  after_destroy :__broadcast_record_destroy__

  def self.live_record_whitelisted_attributes
    []
  end

  private

  def __broadcast_record_update__
    included_attributes = attributes.slice( *(self.class.live_record_whitelisted_attributes & changed) )
    message_data = { 'action' => 'update', 'attributes' => included_attributes }
    LiveRecordChannel.broadcast_to(self, message_data)
    LiveRecordUpdate.create!(recordable: self)
  end

  def __broadcast_record_destroy__
    message_data = { 'action' => 'destroy' }
    LiveRecordChannel.broadcast_to(self, message_data)
  end
end
