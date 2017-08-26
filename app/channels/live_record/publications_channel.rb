class LiveRecord::PublicationsChannel < ApplicationCable::Channel

  def subscribed
  	model_class = params[:model_name].safe_constantize

    if !(model_class && model_class < ApplicationRecord)
      respond_with_error(:bad_request, 'Not a correct model name')
      reject_subscription
    end

    stream_from "live_record_publications_#{params[:model_name].underscore}", coder: ActiveSupport::JSON do |message|
    	newly_created_record = model_class.find(message['attributes']['id'])
    	active_record_relation = model_class.all

    	params[:conditions].each do |condition|
    		condition.each do |key, value|
    			case key
    			when 'where'
    				raise "Invalid `:where` having a value of #{value}. Should be a Hash" unless value.is_a? Hash
    				active_record_relation = active_record_relation.where(value.symbolize_keys)
    			else
    				raise "invalid #{key} value."
    			end
    		end
    	end

    	if active_record_relation.exists?(id: newly_created_record.id)
    		authorised_attributes = authorised_attributes(newly_created_record, current_user)

    		# if not just :id
    		if authorised_attributes.size > 1
	    		message = { 'action' => 'create', 'attributes' => message['attributes'] }
	        response = filtered_message(message, authorised_attributes)
	    		transmit response if response.present?
	    	end
    	end
    end
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

  def respond_with_error(type, message = nil)
    case type
    when :forbidden
      transmit error: { 'code' => 'forbidden', 'message' => (message || 'You are not authorised') }
    when :bad_request
      transmit error: { 'code' => 'bad_request', 'message' => (message || 'Invalid request parameters') }
    end
  end
end