class LiveRecord::BaseChannel < ActionCable::Channel::Base

  protected

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