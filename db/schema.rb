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

ActiveRecord::Schema.define(:version => 20140827132718) do

  create_table "attribute_constraints", :force => true do |t|
    t.integer  "node_id"
    t.string   "attribute_name"
    t.string   "value"
    t.string   "operator"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

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

  create_table "nodes", :force => true do |t|
    t.integer  "pattern_id"
    t.boolean  "root_node"
    t.integer  "x",          :default => 0
    t.integer  "y",          :default => 0
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "ontologies", :force => true do |t|
    t.string   "url"
    t.text     "description"
    t.string   "prefix_url"
    t.string   "short_name"
    t.string   "group"
    t.boolean  "does_exist",    :default => true
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.string   "type"
    t.integer  "repository_id"
  end

  create_table "ontologies_patterns", :id => false, :force => true do |t|
    t.integer "ontology_id"
    t.integer "pattern_id"
  end

  create_table "patterns", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "repository_name"
    t.text     "original_query"
    t.integer  "query_language_cd"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "type"
    t.integer  "pattern_id"
    t.integer  "repository_id"
  end

  add_index "patterns", ["pattern_id"], :name => "index_patterns_on_pattern_id"
  add_index "patterns", ["repository_id"], :name => "index_patterns_on_repository_id"

  create_table "patterns_swe_patterns", :id => false, :force => true do |t|
    t.integer "pattern_id"
    t.integer "swe_pattern_id"
  end

  create_table "relation_constraints", :force => true do |t|
    t.integer  "source_id"
    t.integer  "target_id"
    t.string   "min_cardinality"
    t.string   "max_cardinality"
    t.string   "min_path_length"
    t.string   "max_path_length"
    t.string   "relation_type"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "relations", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "repositories", :force => true do |t|
    t.string  "name"
    t.string  "db_name"
    t.string  "db_username"
    t.string  "db_password"
    t.string  "host"
    t.integer "port"
    t.text    "description"
    t.string  "type"
    t.integer "rdbms_type_cd"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "swe_patterns", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], :name => "taggings_idx", :unique => true

  create_table "tags", :force => true do |t|
    t.string  "name"
    t.integer "taggings_count", :default => 0
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "type_expressions", :force => true do |t|
    t.string   "operator"
    t.string   "rdf_type"
    t.integer  "node_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "ancestry"
  end

  add_index "type_expressions", ["ancestry"], :name => "index_type_expressions_on_ancestry"

end
