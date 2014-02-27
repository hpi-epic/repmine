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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140220144301) do

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "ontologies", :force => true do |t|
    t.string   "url"
    t.text     "description"
    t.string   "prefix_url"
    t.string   "short_name"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "type"
    t.integer  "repository_id"
  end

  create_table "ontologies_queries", :id => false, :force => true do |t|
    t.integer "ontology_id"
    t.integer "query_id"
  end

  create_table "queries", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "repository_name"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "query_attribute_constraints", :force => true do |t|
    t.integer  "query_node_id"
    t.string   "attribute_name"
    t.string   "value"
    t.string   "operator"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "query_nodes", :force => true do |t|
    t.integer  "query_id"
    t.string   "rdf_type"
    t.boolean  "root_node"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "query_relation_constraints", :force => true do |t|
    t.integer  "source_id"
    t.integer  "target_id"
    t.string   "min_cardinality"
    t.string   "max_cardinality"
    t.string   "min_path_length"
    t.string   "max_path_length"
    t.string   "relation_name"
    t.integer  "query_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "query_time_constraints", :force => true do |t|
    t.integer  "from_id"
    t.integer  "to_id"
    t.decimal  "min_time"
    t.decimal  "max_time"
    t.boolean  "return_timepspan"
    t.string   "variable_name"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "repositories", :force => true do |t|
    t.string  "name"
    t.string  "host"
    t.integer "port"
    t.text    "description"
    t.string  "type"
    t.string  "database_name"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

end
