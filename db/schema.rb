# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_17_222059) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chains", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code"
    t.text "comments"
    t.integer "company_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_chains_on_active"
    t.index ["company_id", "code"], name: "index_chains_on_company_id_and_code", unique: true
    t.index ["company_id"], name: "index_chains_on_company_id"
  end

  create_table "companies", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "formats", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "chain_id", null: false
    t.string "code"
    t.text "comments"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_formats_on_active"
    t.index ["chain_id", "code"], name: "index_formats_on_chain_id_and_code", unique: true
    t.index ["chain_id"], name: "index_formats_on_chain_id"
  end

  create_table "price_updates", force: :cascade do |t|
    t.datetime "applied_at"
    t.integer "company_id", null: false
    t.datetime "created_at", null: false
    t.decimal "new_price", precision: 10, scale: 2, null: false
    t.text "notes"
    t.integer "product_presentation_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "store_id"
    t.datetime "updated_at", null: false
    t.integer "visit_id"
    t.index ["company_id", "status"], name: "index_price_updates_on_company_id_and_status"
    t.index ["company_id"], name: "index_price_updates_on_company_id"
    t.index ["product_presentation_id"], name: "index_price_updates_on_product_presentation_id"
    t.index ["store_id", "status"], name: "index_price_updates_on_store_id_and_status"
    t.index ["store_id"], name: "index_price_updates_on_store_id"
    t.index ["visit_id", "status"], name: "index_price_updates_on_visit_id_and_status"
    t.index ["visit_id"], name: "index_price_updates_on_visit_id"
  end

  create_table "product_families", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "company_id", null: false
    t.datetime "created_at", precision: nil
    t.string "name"
    t.datetime "updated_at", precision: nil
  end

  create_table "product_presentations", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "barcode"
    t.string "code", null: false
    t.text "comments"
    t.datetime "created_at", null: false
    t.integer "product_id", null: false
    t.decimal "size", precision: 10, scale: 2
    t.integer "unit_of_measure_id", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_product_presentations_on_active"
    t.index ["barcode"], name: "index_product_presentations_on_barcode", unique: true
    t.index ["product_id", "code"], name: "index_product_presentations_on_product_id_and_code", unique: true
    t.index ["product_id"], name: "index_product_presentations_on_product_id"
    t.index ["unit_of_measure_id"], name: "index_product_presentations_on_unit_of_measure_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "code"
    t.text "comments"
    t.integer "company_id", null: false
    t.datetime "created_at", precision: nil
    t.string "description"
    t.string "name"
    t.integer "product_family_id", null: false
    t.datetime "updated_at", precision: nil
  end

  create_table "routes", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "comments"
    t.integer "company_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_routes_on_active"
    t.index ["company_id"], name: "index_routes_on_company_id"
    t.index ["name", "company_id"], name: "index_routes_on_name_and_company_id", unique: true
  end

  create_table "segments", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "company_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_segments_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_segments_on_company_id"
  end

  create_table "stores", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "address"
    t.integer "chain_id", null: false
    t.text "comments"
    t.integer "company_id", null: false
    t.datetime "created_at", null: false
    t.integer "format_id", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "manager_name"
    t.string "manager_phone"
    t.string "name", null: false
    t.integer "route_id"
    t.integer "segment_id"
    t.datetime "updated_at", null: false
    t.integer "visit_day"
    t.integer "visit_frequency", default: 0
    t.index ["active"], name: "index_stores_on_active"
    t.index ["chain_id"], name: "index_stores_on_chain_id"
    t.index ["company_id"], name: "index_stores_on_company_id"
    t.index ["format_id"], name: "index_stores_on_format_id"
    t.index ["name", "company_id"], name: "index_stores_on_name_and_company_id", unique: true
    t.index ["route_id"], name: "index_stores_on_route_id"
    t.index ["segment_id"], name: "index_stores_on_segment_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.json "config", default: {}
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon_url"
    t.text "instructions_template"
    t.string "name", null: false
    t.string "task_type", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_tasks_on_active"
    t.index ["code"], name: "index_tasks_on_code", unique: true
    t.index ["task_type"], name: "index_tasks_on_task_type"
  end

  create_table "unit_of_measures", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "company_id", null: false
    t.datetime "created_at", precision: nil
    t.string "name"
    t.datetime "updated_at", precision: nil
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "company_id", null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "visit_task_responses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "response_data", default: {}
    t.datetime "updated_at", null: false
    t.integer "visit_id", null: false
    t.integer "work_plan_task_id", null: false
    t.index ["visit_id", "work_plan_task_id"], name: "index_visit_task_responses_unique", unique: true
    t.index ["visit_id"], name: "index_visit_task_responses_on_visit_id"
    t.index ["work_plan_task_id"], name: "index_visit_task_responses_on_work_plan_task_id"
  end

  create_table "visits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "scheduled_date", null: false
    t.integer "status", default: 0, null: false
    t.integer "store_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["scheduled_date"], name: "index_visits_on_scheduled_date"
    t.index ["status"], name: "index_visits_on_status"
    t.index ["store_id", "scheduled_date"], name: "index_visits_on_store_id_and_scheduled_date"
    t.index ["store_id"], name: "index_visits_on_store_id"
    t.index ["user_id", "scheduled_date"], name: "index_visits_on_user_id_and_scheduled_date"
    t.index ["user_id"], name: "index_visits_on_user_id"
  end

  create_table "work_plan_tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data", default: {}
    t.text "instructions"
    t.integer "position", default: 0, null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.integer "work_plan_id", null: false
    t.index ["task_id"], name: "index_work_plan_tasks_on_task_id"
    t.index ["work_plan_id", "position"], name: "index_work_plan_tasks_on_work_plan_id_and_position"
    t.index ["work_plan_id"], name: "index_work_plan_tasks_on_work_plan_id"
  end

  create_table "work_plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.integer "company_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "format_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_work_plans_on_active"
    t.index ["company_id", "code"], name: "index_work_plans_on_company_id_and_code", unique: true
    t.index ["company_id"], name: "index_work_plans_on_company_id"
    t.index ["format_id"], name: "index_work_plans_on_format_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chains", "companies"
  add_foreign_key "formats", "chains"
  add_foreign_key "price_updates", "companies"
  add_foreign_key "price_updates", "product_presentations"
  add_foreign_key "price_updates", "stores"
  add_foreign_key "price_updates", "visits"
  add_foreign_key "product_families", "companies"
  add_foreign_key "product_presentations", "products"
  add_foreign_key "product_presentations", "unit_of_measures"
  add_foreign_key "products", "companies"
  add_foreign_key "products", "product_families"
  add_foreign_key "routes", "companies"
  add_foreign_key "segments", "companies"
  add_foreign_key "stores", "chains"
  add_foreign_key "stores", "companies"
  add_foreign_key "stores", "formats"
  add_foreign_key "stores", "routes"
  add_foreign_key "stores", "segments"
  add_foreign_key "unit_of_measures", "companies"
  add_foreign_key "users", "companies"
  add_foreign_key "visit_task_responses", "visits"
  add_foreign_key "visit_task_responses", "work_plan_tasks"
  add_foreign_key "visits", "stores"
  add_foreign_key "visits", "users"
  add_foreign_key "work_plan_tasks", "tasks"
  add_foreign_key "work_plan_tasks", "work_plans"
  add_foreign_key "work_plans", "companies"
  add_foreign_key "work_plans", "formats"
end
