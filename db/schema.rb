# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_07_05_023840) do

  create_table "interface_logs", force: :cascade do |t|
    t.string "controller_name"
    t.string "action_name"
    t.text "request_header"
    t.text "request_body"
    t.text "response_header"
    t.text "response_body"
    t.text "params"
    t.string "business_id"
    t.string "unit_id"
    t.string "request_ip"
    t.string "status"
    t.integer "parent_id"
    t.string "parent_type"
    t.string "business_code"
    t.string "request_url"
    t.text "error_msg"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "interface_senders", force: :cascade do |t|
    t.string "url"
    t.string "host"
    t.string "port"
    t.string "interface_type"
    t.string "http_type"
    t.string "callback_class"
    t.string "callback_method"
    t.text "callback_params"
    t.string "status"
    t.integer "send_times"
    t.datetime "next_time"
    t.text "header"
    t.text "body"
    t.datetime "last_time"
    t.text "last_response"
    t.text "last_header"
    t.string "interface_code"
    t.integer "max_times"
    t.integer "interval"
    t.text "error_msg"
    t.string "parent_class"
    t.integer "parent_id"
    t.integer "unit_id"
    t.integer "business_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "roles", force: :cascade do |t|
    t.integer "user_id"
    t.integer "unit_id"
    t.string "role"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "units", force: :cascade do |t|
    t.string "name"
    t.string "desc"
    t.string "no"
    t.string "short_name"
    t.integer "level"
    t.integer "parent_id"
    t.string "unit_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_units_on_name", unique: true
  end

  create_table "up_downloads", force: :cascade do |t|
    t.string "name"
    t.string "use"
    t.string "desc"
    t.string "ver_no"
    t.string "url"
    t.datetime "oper_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "user_logs", force: :cascade do |t|
    t.integer "user_id", default: 0, null: false
    t.string "operation", default: "", null: false
    t.string "object_class"
    t.integer "object_primary_key"
    t.string "object_symbol"
    t.string "desc"
    t.integer "parent_id"
    t.string "parent_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "username", default: "", null: false
    t.string "role", default: "", null: false
    t.string "name"
    t.string "status"
    t.integer "unit_id"
    t.datetime "locked_at"
    t.integer "failed_attempts", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

end
