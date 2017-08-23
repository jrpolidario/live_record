class Post < ApplicationRecord
	include LiveRecord::Model::Callbacks

	has_many :live_record_updates, as: :recordable

  def self.live_record_whitelisted_attributes(post, current_user)
	  # Add attributes to this array that you would like current_user to have access to.
	  # Defaults to empty array, thereby blocking everything by default, only unless explicitly stated here so.
	  [:title]
  end
end
