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

    if !(model_class && LiveRecord::BaseChannel::Helpers.queryable_attributes(model_class, current_user).present?)
      respond_with_error(:forbidden, 'You do not have privileges to query')
      reject_subscription
    end

    stream_from "live_record:publications:#{params[:model_name].underscore}", coder: ActiveSupport::JSON do |message|
      newly_created_record = model_class.find(message['attributes']['id'])

      active_record_relation = LiveRecord::BaseChannel::SearchAdapters.mapped_active_record_relation(
        model_class: model_class,
        conditions_hash: params[:where].to_h,
        current_user: current_user
      )

      if active_record_relation.exists?(id: newly_created_record.id)
        whitelisted_attributes = LiveRecord::BaseChannel::Helpers.whitelisted_attributes(newly_created_record, current_user)

        if whitelisted_attributes.size > 0
          message = { 'action' => 'create', 'attributes' => message['attributes'] }
          response = filtered_message(message, whitelisted_attributes)
          transmit response if response.present?
        end
      end
    end
  end

  # TODO: split up sync_records action because it currently both handles "syncing" and "reloading"
  def sync_records(data)
    params = data.symbolize_keys
    model_class = params[:model_name].safe_constantize

    if model_class && model_class < ApplicationRecord
      is_being_reloaded = params[:stale_since].blank?
      is_being_synced = params[:stale_since].present?

      active_record_relation = LiveRecord::BaseChannel::SearchAdapters.mapped_active_record_relation(
        model_class: model_class,
        conditions_hash: params[:where].to_h,
        current_user: current_user,
      )

      if is_being_synced
        active_record_relation = active_record_relation.where(
          'created_at >= ?', DateTime.parse(params[:stale_since]) - LiveRecord.configuration.sync_record_buffer_time
        )
      end

      # we `transmmit` a message back to client for each matching record
      active_record_relation.find_each do |record|
        # but first, check for the authorised attributes, if exists
        whitelisted_attributes = LiveRecord::BaseChannel::Helpers.whitelisted_attributes(record, current_user)

        if whitelisted_attributes.size > 0
          message = { 'action' => 'create', 'attributes' => record.attributes }
          response = filtered_message(message, whitelisted_attributes)
          transmit response if response.present?
        end
      end

      # if being reloaded, we finally still transmit a "done" action indicating that reloading has just finished
      if is_being_reloaded
        response = { 'action' => 'afterReload', 'recordIds' => active_record_relation.pluck(:id) }
        transmit response
      end
    else
      respond_with_error(:bad_request, 'Not a correct model name')
      reject_subscription
    end
  end
end
