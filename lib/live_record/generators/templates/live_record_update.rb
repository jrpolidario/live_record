class LiveRecordUpdate < ApplicationRecord
  belongs_to :recordable, polymorphic: true
end
