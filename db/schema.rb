# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150719152534) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "builds", force: :cascade do |t|
    t.integer  "repo_id"
    t.string   "branch"
    t.string   "sha",        limit: 40
    t.boolean  "success"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "repos", force: :cascade do |t|
    t.string   "service"
    t.string   "organization"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "private_key"
  end

  create_table "user_repos", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "repo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "provider"
    t.string   "uid"
    t.string   "email"
    t.string   "avatar"
    t.string   "token"
    t.string   "secret"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
