class LiveRecordChannel < ApplicationCable::Channel
  include ActiveSupport::Rescuable

  def subscribed
    find_record_from_params(params) do |record|
      stream_for record, coder: ActiveSupport::JSON do |message|
        if connection.live_record_authorised?(record)
          transmit message
        else
          responds_with_error(:forbidden)
        end
      end
    end
  end

  def sync_record(data)
    find_record_from_params(data.symbolize_keys) do |record|
      if connection.live_record_authorised?(record)
        live_record_update = LiveRecordUpdate.where(
          recordable_type: record.class.name,
          recordable_id: record.id
        ).where(
          'created_at >= ?', DateTime.parse(data['stale_since']) - 1.minute
        ).order(id: :asc)

        if live_record_update.exists?
          included_attributes = record.attributes.slice(*record.class.live_record_whitelisted_attributes)
          transmit 'action' => 'update', 'attributes' => included_attributes
        end
      else
        responds_with_error(:forbidden)
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
        transmit 'action' => 'destroy'
      end
    else
      responds_with_error(:bad_request, 'Not a correct model name')
    end
  end

  def responds_with_error(type, message = nil)
    case type
    when :forbidden
      transmit error: { code: 'forbidden', message: (message || 'You are not authorised') }
    when :bad_request
      transmit error: { code: 'bad_request', message: (message || 'Invalid request parameters') }
    end
  end
end
