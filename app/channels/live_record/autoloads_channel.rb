class LiveRecord::AutoloadsChannel < LiveRecord::BaseChannel
  def subscribed
    stream_from 'live_record:autoloads', coder: ActiveSupport::JSON do |message|
      new_or_updated_record = message['model_name'].safe_constantize.find_by(id: message['record_id']) || break
      new_or_changed_attributes = message.fetch('attributes')

      is_autoload_dependent_to_new_or_changed_attributes = false

      conditions_hash = params[:where].to_h

      # if no conditions supplied to autoload(), then it means every attribute is dependent
      if conditions_hash.empty?
        is_autoload_dependent_to_new_or_changed_attributes = true
      else
        @autoload_dependent_attributes ||= [].tap do |autoload_dependent_attributes|
          conditions_hash.each do |key, value|
            operator = key.split('_').last
            # to get attribute_name, we subtract the end part of the string with size of operator substring; i.e.: created_at_lteq -> created_at
            attribute_name = key[0..(-1 - operator.size - 1)]

            autoload_dependent_attributes << attribute_name
          end
        end

        @autoload_dependent_attributes.each do |autoload_dependent_attribute|
          if new_or_changed_attributes.include? autoload_dependent_attribute
            is_autoload_dependent_to_new_or_changed_attributes = true
            break
          end
        end
      end

      # now if this autoload subscription is indeed dependent on the attributes,
      # then we now check if the where condition values actually match
      # and then transmit data if authorised attributes match condition values
      if is_autoload_dependent_to_new_or_changed_attributes
        model_class = params[:model_name].safe_constantize

        active_record_relation = LiveRecord::BaseChannel::SearchAdapters.mapped_active_record_relation(
          model_class: model_class,
          conditions_hash: conditions_hash,
          current_user: current_user,
        )

        if active_record_relation.exists?(id: new_or_updated_record.id)
          whitelisted_attributes = LiveRecord::BaseChannel::Helpers.whitelisted_attributes(new_or_updated_record, current_user)

          if whitelisted_attributes.size > 0
            message = { 'action' => 'createOrUpdate', 'attributes' => new_or_updated_record.attributes }
            response = filtered_message(message, whitelisted_attributes)
            transmit response if response.present?
          end
        end
      end
    end
  end

  def sync_records(data)
    params = data.symbolize_keys
    model_class = params[:model_name].safe_constantize

    if model_class && model_class < ApplicationRecord

      active_record_relation = LiveRecord::BaseChannel::SearchAdapters.mapped_active_record_relation(
        model_class: model_class,
        conditions_hash: params[:where].to_h,
        current_user: current_user,
      )

      if params[:stale_since].present?
        active_record_relation = active_record_relation.where(
          'updated_at >= ?', DateTime.parse(params[:stale_since]) - LiveRecord.configuration.sync_record_buffer_time
        )
      end

      # we `transmmit` a message back to client for each matching record
      active_record_relation.find_each do |record|
        # but first, check for the authorised attributes, if exists
        whitelisted_attributes = LiveRecord::BaseChannel::Helpers.whitelisted_attributes(record, current_user)

        if whitelisted_attributes.size > 0
          message = { 'action' => 'createOrUpdate', 'attributes' => record.attributes }
          response = filtered_message(message, whitelisted_attributes)
          transmit response if response.present?
        end
      end
    else
      respond_with_error(:bad_request, 'Not a correct model name')
      reject_subscription
    end
  end
end
