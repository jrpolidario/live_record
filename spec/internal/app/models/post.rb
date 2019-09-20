class Post < ApplicationRecord
  include LiveRecord::Model::Callbacks

  belongs_to :user
  belongs_to :category
  has_many :live_record_updates, as: :recordable, dependent: :destroy

  validates :title, presence: true

  def self.live_record_readable_attributes(post, current_user)
    [:id, :title, :is_enabled, :category_id, :user_id, :created_at, :updated_at]
  end

  def self.live_record_updateable_attributes(post, current_user)
    [:title, :is_enabled, :category_id, :user_id]
  end

  def self.live_record_queryable_attributes(current_user)
    [:id, :title, :is_enabled, :category_id, :user_id, :created_at, :updated_at]
  end
end
