class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  has_many :live_record_update, as: :recordable

  after_update :__broadcast_record_update__
  after_destroy :__broadcast_record_destroy__

  private

  def __broadcast_record_update__
    message_data = { 'action' => 'update', 'attributes' => attributes.slice( *(self.class.live_record_whitelisted_attributes & changed) ) }
    LiveRecordChannel.broadcast_to(self, message_data)
    LiveRecordUpdate.create!(recordable: self)
  end

  def __broadcast_record_destroy__
    message_data = { 'action' => 'destroy' }
    LiveRecordChannel.broadcast_to(self, message_data)
  end
end
