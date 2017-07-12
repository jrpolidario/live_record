class Post < ApplicationRecord
  scope :enabled, -> { where(is_enabled: true) }
  
  def self.live_record_whitelisted_attributes(record, current_user)
  	if current_user
	    %w[
	      title
	      content
	      created_at
	      updated_at
	    ]
	  else
	  	if record.is_enabled
		  	%w[
		  		title
		  	]
		  else
		  	[]
		  end
	  end
  end
end
