class CreateLiveRecordMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :live_record_messages do |t|
      t.references :recordable, polymorphic: true
      t.text :message_data

      t.datetime :created_at, null: false, index: true
    end
  end
end
