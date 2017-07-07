class Post < ApplicationRecord
	scope :enabled, -> { where(is_enabled: true) }
end
