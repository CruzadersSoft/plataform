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

ActiveRecord::Schema[8.1].define(version: 2026_04_28_124000) do
  create_table "church_invitation_codes", force: :cascade do |t|
    t.integer "church_id", null: false
    t.integer "church_role", default: 0, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.datetime "expires_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "status"], name: "index_church_invitation_codes_on_church_id_and_status"
    t.index ["church_id"], name: "index_church_invitation_codes_on_church_id"
    t.index ["code"], name: "index_church_invitation_codes_on_code", unique: true
    t.index ["created_by_id"], name: "index_church_invitation_codes_on_created_by_id"
  end

  create_table "church_memberships", force: :cascade do |t|
    t.integer "church_id", null: false
    t.integer "church_role", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "invited_by_id"
    t.datetime "joined_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["church_id", "church_role", "status"], name: "idx_on_church_id_church_role_status_06abf71556"
    t.index ["church_id", "user_id"], name: "index_church_memberships_on_church_id_and_user_id", unique: true
    t.index ["church_id"], name: "index_church_memberships_on_church_id"
    t.index ["invited_by_id"], name: "index_church_memberships_on_invited_by_id"
    t.index ["user_id"], name: "index_church_memberships_on_user_id"
  end

  create_table "churches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "legal_name"
    t.string "name", null: false
    t.string "phone"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.string "timezone", default: "America/Sao_Paulo", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_churches_on_slug", unique: true
    t.index ["status"], name: "index_churches_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.integer "platform_role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "church_invitation_codes", "churches"
  add_foreign_key "church_invitation_codes", "users", column: "created_by_id"
  add_foreign_key "church_memberships", "churches"
  add_foreign_key "church_memberships", "users"
  add_foreign_key "church_memberships", "users", column: "invited_by_id"
  add_foreign_key "sessions", "users"
end
