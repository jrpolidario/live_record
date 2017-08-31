class LiveRecord::ChangesChannel < LiveRecord::BaseChannel

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
end