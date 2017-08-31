class LiveRecord::PublicationsChannel < LiveRecord::BaseChannel

  def subscribed
  	model_class = params[:model_name].safe_constantize

    if !(model_class && model_class < ApplicationRecord)
      respond_with_error(:bad_request, 'Not a correct model name')
      reject_subscription
    end

    stream_from "live_record:publications:#{params[:model_name].underscore}", coder: ActiveSupport::JSON do |message|
    	newly_created_record = model_class.find(message['attributes']['id'])
    	active_record_relation = model_class.all

			if params[:where].is_a? Hash
				active_record_relation = active_record_relation.where(params[:where].symbolize_keys)
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
end