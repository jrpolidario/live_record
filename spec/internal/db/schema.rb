ActiveRecord::Schema.define do
  create_table "live_record_updates", force: :cascade do |t|
    t.string "recordable_type"
    t.integer "recordable_id"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_live_record_updates_on_created_at"
    t.index ["recordable_type", "recordable_id"], name: "index_live_record_updates_on_recordable_type_and_recordable_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.boolean "is_enabled"
    t.integer "user_id"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_enabled"], name: "index_posts_on_is_enabled"
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["category_id"], name: "index_posts_on_category_id"
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["updated_at"], name: "index_posts_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["updated_at"], name: "index_users_on_updated_at"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_categories_on_created_at"
    t.index ["updated_at"], name: "index_categories_on_updated_at"
  end
end
