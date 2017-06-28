class AddIsEnabledToPosts < ActiveRecord::Migration[5.0]
  def change
    add_column :posts, :is_enabled, :boolean
    add_index :posts, :is_enabled
  end
end
