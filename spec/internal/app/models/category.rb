class Category < ApplicationRecord
  include LiveRecord::Model::Callbacks

  has_many :live_record_updates, as: :recordable, dependent: :destroy
  has_many :posts

  def self.live_record_readable_attributes(category, current_user)
    [:id, :name, :created_at, :updated_at]
  end

  def self.live_record_queryable_attributes(current_user)
    [:id, :name, :created_at, :updated_at]
  end
end
