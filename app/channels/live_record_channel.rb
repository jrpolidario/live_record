class LiveRecordChannel < ApplicationCable::Channel
  class ForbiddenError < StandardError; end
  class BadRequestError < StandardError; end

  def subscribed
    find_record_from_params(params) do |record|
      stream_for record, coder: ActiveSupport::JSON do |message|
        if connection.live_record_authorised?(record)
          transmit message
        else
          raise ForbiddenError, 'You are not authorised'
        end
      end
    end
  end

  def sync_record(data)
    find_record_from_params(data.symbolize_keys) do |record|
      if connection.live_record_authorised?(record)
        last_live_record_message = LiveRecordMessage.where(
          recordable_type: record.class.name,
          recordable_id: record.id
        ).where(
          'created_at >= ?', DateTime.parse(data['stale_since']) - 1.minute
        ).order(id: :asc).last

        if last_live_record_message.present?
          transmit(JSON.parse(last_live_record_message.message_data))
        end
      else
        raise ForbiddenError, 'You are not authorised'
      end
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def find_record_from_params(params)
    model_class = params[:model_name].safe_constantize

    if model_class && model_class < ApplicationRecord
      record = model_class.find_by(id: params[:record_id])

      if record.present?
        yield record
      else
        transmit action: 'destroy'
      end
    else
      raise BadRequestError, 'Not a correct model name'
    end
  end
end
