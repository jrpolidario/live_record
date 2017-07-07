class LiveRecordMessage < ApplicationRecord
  belongs_to :recordable, polymorphic: true
end
