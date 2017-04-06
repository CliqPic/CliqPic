# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170406211303) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "albums", force: :cascade do |t|
    t.text     "name",       null: false
    t.integer  "event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_albums_on_event_id", using: :btree
  end

  create_table "events", force: :cascade do |t|
    t.integer  "user_id",                         null: false
    t.text     "name",                            null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "location"
    t.float    "loc_lat"
    t.float    "loc_lon"
    t.text     "hashtags"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "fetching_images", default: false
    t.index ["user_id"], name: "index_events_on_user_id", using: :btree
  end

  create_table "images", force: :cascade do |t|
    t.integer  "instagram_id"
    t.text     "instagram_link"
    t.text     "thumbnail_url"
    t.text     "low_res_url"
    t.text     "high_res_url"
    t.text     "hashtags"
    t.datetime "created_on_instagram_at"
    t.integer  "user_id"
    t.integer  "event_id"
    t.integer  "album_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["album_id"], name: "index_images_on_album_id", using: :btree
    t.index ["event_id"], name: "index_images_on_event_id", using: :btree
    t.index ["user_id"], name: "index_images_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider",                            null: false
    t.string   "uid",                                 null: false
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.text     "access_token"
    t.text     "first_name"
    t.text     "last_name"
    t.text     "middle_name"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  add_foreign_key "albums", "events"
  add_foreign_key "events", "users"
  add_foreign_key "images", "albums"
  add_foreign_key "images", "events"
  add_foreign_key "images", "users"
end
