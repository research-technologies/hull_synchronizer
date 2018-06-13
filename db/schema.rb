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

ActiveRecord::Schema.define(version: 20_180_531_002_852) do
  create_table 'data_mappers', force: :cascade do |t|
    t.string 'title'
    t.string 'file_type'
    t.integer 'rows'
    t.integer 'rows_processed'
    t.string 'status'
    t.text 'message'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'original_file_file_name'
    t.string 'original_file_content_type'
    t.integer 'original_file_file_size'
    t.datetime 'original_file_updated_at'
    t.string 'mapped_file_file_name'
    t.string 'mapped_file_content_type'
    t.integer 'mapped_file_file_size'
    t.datetime 'mapped_file_updated_at'
  end
end
