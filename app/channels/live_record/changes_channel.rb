class LiveRecord::ChangesChannel < ApplicationCable::Channel

  def subscribed
    find_record_from_params(params) do |record|
      authorised_attributes = authorised_attributes(record, current_user)

      if authorised_attributes.present?
        stream_for record, coder: ActiveSupport::JSON do |message|
          begin
            record.reload
          rescue ActiveRecord::RecordNotFound
          end
          
          authorised_attributes = authorised_attributes(record, current_user)

          # if not just :id
          if authorised_attributes.size > 1
            response = filtered_message(message, authorised_attributes)
            transmit response if response.present?
          else
            respond_with_error(:forbidden)
            reject_subscription
          end
        end
      else
        respond_with_error(:forbidden)
        reject
      end
    end
  end

  def sync_record(data)
    find_record_from_params(data.symbolize_keys) do |record|
      authorised_attributes = authorised_attributes(record, current_user)

      # if not just :id
      if authorised_attributes.size > 1
        live_record_update = LiveRecordUpdate.where(
          recordable_type: record.class.name,
          recordable_id: record.id
        ).where(
          'created_at >= ?', DateTime.parse(data['stale_since']) - 1.minute
        ).order(id: :asc)

        if live_record_update.exists?
          message = { 'action' => 'update', 'attributes' => record.attributes }
          response = filtered_message(message, authorised_attributes)
          transmit response if response.present?
        end
      else
        respond_with_error(:forbidden)
        reject_subscription
      end
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def authorised_attributes(record, current_user)
    whitelisted_attributes = record.class.live_record_whitelisted_attributes(record, current_user)
    raise "#{record.model}.live_record_whitelisted_attributes should return an array" unless whitelisted_attributes.is_a? Array 
    ([:id] + whitelisted_attributes).map(&:to_s)
  end

  def filtered_message(message, filters)
    message['attributes'].slice!(*filters) if message['attributes'].present?
    message
  end

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
      respond_with_error(:bad_request, 'Not a correct model name')
      reject_subscription
    end
  end

  def respond_with_error(type, message = nil)
    case type
    when :forbidden
      transmit error: { 'code' => 'forbidden', 'message' => (message || 'You are not authorised') }
    when :bad_request
      transmit error: { 'code' => 'bad_request', 'message' => (message || 'Invalid request parameters') }
    end
  end
end