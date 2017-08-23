class LiveRecordChannel < ApplicationCable::Channel
  include LiveRecord::Channel::Implement
end
