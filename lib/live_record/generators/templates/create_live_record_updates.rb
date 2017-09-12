class CreateLiveRecordUpdates < ActiveRecord::Migration[5.0]
  def change
    create_table :live_record_updates do |t|
      t.references :recordable, polymorphic: true
      t.datetime :created_at, null: false, index: true
    end
  end
end