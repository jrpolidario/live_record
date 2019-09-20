# This channel streams changes (update/destroy) from records to connected clients, through ActiveRecord callbacks
# This also supports syncing (old changes) when a client somehow got disconnected (i.e. network problems),
# through a separate cache `live_record_updates` table.
class LiveRecord::ChangesChannel < LiveRecord::BaseChannel

  def subscribed
    find_record_from_params(params) do |record|
      readable_attributes = LiveRecord::BaseChannel::Helpers.readable_attributes(record, current_user)

      if readable_attributes.present?
        stream_for record, coder: ActiveSupport::JSON do |message|
          begin
            record.reload
          rescue ActiveRecord::RecordNotFound
          end

          readable_attributes = LiveRecord::BaseChannel::Helpers.readable_attributes(record, current_user)

          if readable_attributes.size > 0
            response = filtered_message(message, readable_attributes)
            transmit response if response.present?
          else
            respond_with_error(:forbidden)
            # reject_subscription
          end
        end
      else
        respond_with_error(:forbidden)
        # reject
      end
    end
  end

  def sync_record(data)
    params = data.symbolize_keys

    find_record_from_params(params) do |record|
      readable_attributes = LiveRecord::BaseChannel::Helpers.readable_attributes(record, current_user)

      if readable_attributes.size > 0
        live_record_updates = nil

        if params[:stale_since].present?
          live_record_updates = LiveRecordUpdate.where(
            recordable_type: record.class.name,
            recordable_id: record.id
          ).where(
            'created_at >= ?', DateTime.parse(params[:stale_since]) - LiveRecord.configuration.sync_record_buffer_time
          )
        end

        # if stale_since is unknown, or there is a live_record_update that has happened while disconnected,
        # then we update the record in the client-side
        if params[:stale_since].blank? || live_record_updates.exists?
          message = { 'action' => 'update', 'attributes' => record.attributes }
          response = filtered_message(message, readable_attributes)
          transmit response if response.present?
        end
      else
        respond_with_error(:forbidden)
        # reject_subscription
      end
    end
  end

  def update(data)
    params = data.symbolize_keys

    find_record_from_params(params) do |record|
      updateable_attributes = LiveRecord::BaseChannel::Helpers.updateable_attributes(record, current_user)

      if updateable_attributes.size > 0
        whitelisted_changed_attributes = params[:attributes].slice(*updateable_attributes)

        if record.update(whitelisted_changed_attributes)
          # if successful, do nothing: dont transmit any WS response stream for efficiency,
          # as `update` callback will be triggered in the JS client-side anyway
        else
          respond_with_error(:invalid, record.errors.messages)
        end
      else
        respond_with_error(:forbidden)
        # reject_subscription
      end
    end
  end
end
