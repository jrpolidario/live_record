class LiveRecord::BaseChannel < ActionCable::Channel::Base

  module Helpers
    def self.whitelisted_attributes(record, current_user)
      whitelisted_attributes = record.class.live_record_whitelisted_attributes(record, current_user)

      unless whitelisted_attributes.is_a? Array
        raise "#{record.class}.live_record_whitelisted_attributes should return an array"
      end

      whitelisted_attributes = whitelisted_attributes.map(&:to_s)

      if !whitelisted_attributes.empty? && !whitelisted_attributes.include?('id')
        raise "#{record.class}.live_record_whitelisted_attributes should return an array that also includes the :id attribute, as you are authorizing at least one other attribute along with it."
      end

      whitelisted_attributes.to_set
    end

    def self.queryable_attributes(model_class, current_user)
      queryable_attributes = model_class.live_record_queryable_attributes(current_user)
      raise "#{model_class}.live_record_queryable_attributes should return an array" unless queryable_attributes.is_a? Array
      queryable_attributes = queryable_attributes.map(&:to_s)
      queryable_attributes.to_set
    end
  end

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
    end
  end
end
