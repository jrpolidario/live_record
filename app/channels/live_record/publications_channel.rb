# This channel streams new records to connected clients whenever the "where" condition supplied by the client matches
# This implementation can be quite inefficient because there's only one pub-sub queue used for each model, but because of
# constraints ( see https://github.com/jrpolidario/live_record/issues/2 ) and because Users are authorised-validated anyway
# in each stream, then there's already an overhead delay. I am prioritising development convenience (as Rails does), in order
# to achieve a simpler API; in this example, it would be something like in JS:
# `LiveRecord.Model.all.Book.subscribe({where: is_enabled: true})`
class LiveRecord::PublicationsChannel < LiveRecord::BaseChannel

  def subscribed
    model_class = params[:model_name].safe_constantize

    if !(model_class && model_class < ApplicationRecord)
      respond_with_error(:bad_request, 'Not a correct model name')
      reject_subscription
    end

    if !(model_class && model_class.live_record_queryable_attributes(current_user).present?)
      respond_with_error(:forbidden, 'You do not have privileges to query')
      reject_subscription
    end

    stream_from "live_record:publications:#{params[:model_name].underscore}", coder: ActiveSupport::JSON do |message|
      newly_created_record = model_class.find(message['attributes']['id'])

      active_record_relation = SearchAdapters.mapped_active_record_relation(
        model_class: model_class,
        conditions_hash: params[:where].to_h,
        current_user: current_user
      )

      if active_record_relation.exists?(id: newly_created_record.id)
        @authorised_attributes ||= authorised_attributes(newly_created_record, current_user)
        # if not just :id
        if @authorised_attributes.size > 1
          message = { 'action' => 'create', 'attributes' => message['attributes'] }
          response = filtered_message(message, @authorised_attributes)
          transmit response if response.present?
        end
      end
    end
  end

  def sync_records(data)
    params = data.symbolize_keys
    model_class = params[:model_name].safe_constantize

    if model_class && model_class < ApplicationRecord

      active_record_relation = SearchAdapters.mapped_active_record_relation(
        model_class: model_class,
        conditions_hash: params[:where].to_h,
        current_user: current_user,
      )

      if params[:stale_since].present?
        active_record_relation = active_record_relation.where(
          'created_at >= ?', DateTime.parse(params[:stale_since]) - LiveRecord.configuration.sync_record_buffer_time
        )
      end

      # we `transmmit` a message back to client for each matching record
      active_record_relation.find_each do |record|
        # but first, check for the authorised attributes, if exists
        current_authorised_attributes = authorised_attributes(record, current_user)

        message = { 'action' => 'create', 'attributes' => record.attributes }
        response = filtered_message(message, current_authorised_attributes)
        transmit response if response.present?
      end
    else
      respond_with_error(:bad_request, 'Not a correct model name')
      reject_subscription
    end
  end
end
