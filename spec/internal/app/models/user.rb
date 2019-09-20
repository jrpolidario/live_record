class User < ApplicationRecord
  include LiveRecord::Model::Callbacks

  has_many :live_record_updates, as: :recordable, dependent: :destroy
  has_many :posts

  def self.live_record_readable_attributes(user, current_user)
    [:id, :email, :created_at, :updated_at]
  end

  def self.live_record_queryable_attributes(current_user)
    []
  end
end
