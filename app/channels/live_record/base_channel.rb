class LiveRecord::BaseChannel < ActionCable::Channel::Base

  protected

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
    when :invalid
      transmit error: { 'code' => 'invalid', 'message' => message }
    end
  end
end
