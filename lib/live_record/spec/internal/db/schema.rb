ActiveRecord::Schema.define do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "live_record_updates", id: :serial, force: :cascade do |t|
    t.string "recordable_type"
    t.integer "recordable_id"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_live_record_updates_on_created_at"
    t.index ["recordable_type", "recordable_id"], name: "index_live_record_updates_on_recordable_type_and_recordable_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
