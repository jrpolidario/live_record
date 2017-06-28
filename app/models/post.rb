class Post < ApplicationRecord
	scope :enabled, -> { where(is_enabled: true) }

  def self.live_record_scopes(scopes = [])
  	[:enabled]
  end
end
