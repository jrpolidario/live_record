class Post < ApplicationRecord
	scope :enabled, -> { where(is_enabled: true) }

	def self.live_record_whitelisted_attributes
		%w[
			title
			created_at
			updated_at
		]
	end
end
