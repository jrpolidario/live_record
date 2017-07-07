class LiveRecordChannel < ApplicationCable::Channel
  def subscribed
    model_class = params[:model_name].safe_constantize

    if model_class && model_class < ApplicationRecord
      record = model_class.find_by(id: params[:record_id])

      if record.present?
        stream_for record, coder: ActiveSupport::JSON do |message|
          if connection.live_record_authorised?(params)
            transmit message
          end
        end
      else
        transmit action: 'destroy'
      end
    else
      raise ArgumentError, 'Not a correct model name!'
    end
  end

  def sync_record(data)
    last_live_record_message = LiveRecordMessage.where(
      recordable_type: data['model_name'],
      recordable_id: data['record_id']
    ).where(
      'created_at >= ?', DateTime.parse(data['stale_since']) - 1.minute
    ).order(id: :asc).last

    if last_live_record_message.present?
      transmit(JSON.parse(last_live_record_message.message_data))
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
