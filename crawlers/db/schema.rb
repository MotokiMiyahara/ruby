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

ActiveRecord::Schema.define(version: 20140913010731) do

  create_table "gelbooru_images", force: true do |t|
    t.integer  "o_id",       null: false
    t.text     "file_url"
    t.text     "tags"
    t.string   "rating"
    t.string   "md5"
    t.text     "save_path"
    t.text     "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "gelbooru_images", ["o_id"], name: "index_gelbooru_images_on_o_id", unique: true, using: :btree

  create_table "konachan_images", force: true do |t|
    t.integer  "o_id",       null: false
    t.text     "file_url"
    t.text     "tags"
    t.string   "rating"
    t.string   "md5"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "save_path"
    t.text     "source"
  end

  add_index "konachan_images", ["o_id"], name: "index_konachan_images_on_o_id", unique: true, using: :btree

end
