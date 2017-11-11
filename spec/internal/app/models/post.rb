class Post < ApplicationRecord
  include LiveRecord::Model::Callbacks

  belongs_to :user
  has_many :live_record_updates, as: :recordable, dependent: :destroy

  def self.live_record_whitelisted_attributes(post, current_user)
    [:id, :title, :is_enabled, :user_id, :created_at, :updated_at]
  end

  def self.live_record_queryable_attributes(current_user)
    [:id, :title, :is_enabled, :user_id, :created_at, :updated_at]
  end
end
