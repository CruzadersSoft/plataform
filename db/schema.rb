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

ActiveRecord::Schema[8.1].define(version: 2026_04_28_150300) do
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
    t.index ["user_id"], name: "index_church_memberships_on_active_user_id", unique: true, where: "status = 0"
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

  create_table "department_memberships", force: :cascade do |t|
    t.integer "church_id", null: false
    t.datetime "created_at", null: false
    t.integer "department_id", null: false
    t.integer "department_role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["church_id", "department_id", "status"], name: "idx_department_memberships_on_church_department_status"
    t.index ["church_id", "user_id"], name: "index_department_memberships_on_church_id_and_user_id"
    t.index ["church_id"], name: "index_department_memberships_on_church_id"
    t.index ["department_id", "user_id"], name: "index_department_memberships_on_department_id_and_user_id", unique: true
    t.index ["department_id"], name: "index_department_memberships_on_department_id"
    t.index ["user_id"], name: "index_department_memberships_on_user_id"
  end

  create_table "departments", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "church_id", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "active"], name: "index_departments_on_church_id_and_active"
    t.index ["church_id", "name"], name: "index_departments_on_church_id_and_name", unique: true
    t.index ["church_id"], name: "index_departments_on_church_id"
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
  add_foreign_key "department_memberships", "churches"
  add_foreign_key "department_memberships", "departments"
  add_foreign_key "department_memberships", "users"
  add_foreign_key "departments", "churches"
end
