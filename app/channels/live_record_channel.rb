class LiveRecordChannel < ApplicationCable::Channel
  def subscribed
  	stream_name = 'records'
  	stream_name += "_#{params[:model]}" if params[:model].present?
  	stream_name += "_#{params[:action]}" if params[:action].present?
  	stream_name += "_#{params[:id]}" if params[:id].present?
    stream_from stream_name
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
