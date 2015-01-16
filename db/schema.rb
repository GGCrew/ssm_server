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

ActiveRecord::Schema.define(version: 20150116000001) do

  create_table "client_photo_queues", force: true do |t|
    t.integer  "client_id"
    t.integer  "photo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "client_photos", force: true do |t|
    t.integer  "client_id"
    t.integer  "photo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hold_duration"
    t.string   "transition_type"
    t.integer  "transition_duration"
  end

  create_table "clients", force: true do |t|
    t.string   "ip_address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "controls", force: true do |t|
    t.integer  "hold_duration"
    t.integer  "transition_duration"
    t.string   "transition_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "play_state"
    t.boolean  "auto_approve",        default: false
  end

  create_table "photos", force: true do |t|
    t.integer  "camera_id"
    t.date     "date"
    t.string   "filename"
    t.integer  "rotation",       default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "approval_state", default: "pending"
  end

end
