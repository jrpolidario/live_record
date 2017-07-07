class LiveRecordChannel < ApplicationCable::Channel
  def subscribed
    model_class = params[:model].safe_constantize

    if model_class && model_class < ApplicationRecord
      record = model_class.find(params[:id])
      stream_for record, coder: ActiveSupport::JSON do |message|
        if connection.live_record_authorised?(params)
          transmit message
        end
      end
    else
      raise ArgumentError, 'Not a correct model name!'
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
