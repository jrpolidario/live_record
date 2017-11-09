class User < ApplicationRecord
  include LiveRecord::Model::Callbacks

  has_many :live_record_updates, as: :recordable, dependent: :destroy
  has_many :posts

  def self.live_record_whitelisted_attributes(user, current_user)
    # Add attributes to this array that you would like current_user to have access to.
    # Defaults to empty array, thereby blocking everything by default, only unless explicitly stated here so.
    [:email, :created_at, :updated_at]
  end
end
