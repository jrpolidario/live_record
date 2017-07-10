class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  has_many :live_record_messages, as: :recordable

  after_update :__broadcast_record_update__
  after_destroy :__broadcast_record_destroy__

  private

  def __broadcast_record_update__
    message_data = { 'action' => 'update', 'attributes' => attributes.slice(*changed) }
    LiveRecordChannel.broadcast_to(self, message_data)
    LiveRecordMessage.create!(recordable: self, message_data: message_data.to_json)
  end

  def __broadcast_record_destroy__
    message_data = { 'action' => 'destroy' }
    LiveRecordChannel.broadcast_to(self, message_data)
    LiveRecordMessage.create!(recordable: self, message_data: message_data.to_json)
  end
end
