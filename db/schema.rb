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

ActiveRecord::Schema.define(:version => 20150512112041) do

  create_table "ontologies", :force => true do |t|
    t.string   "url"
    t.text     "description"
    t.string   "short_name"
    t.string   "group"
    t.string   "type"
    t.boolean  "does_exist",  :default => true
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "pattern_element_matches", :force => true do |t|
    t.integer  "matched_element_id"
    t.integer  "matching_element_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "pattern_element_matches", ["matched_element_id"], :name => "index_pattern_element_matches_on_matched_element_id"
  add_index "pattern_element_matches", ["matching_element_id"], :name => "index_pattern_element_matches_on_matching_element_id"

  create_table "pattern_elements", :force => true do |t|
    t.string   "type"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "pattern_id"
    t.integer  "node_id"
    t.string   "value"
    t.string   "operator"
    t.string   "min_cardinality"
    t.string   "max_cardinality"
    t.string   "min_path_length"
    t.string   "max_path_length"
    t.integer  "source_id"
    t.integer  "target_id"
    t.integer  "x",               :default => 0
    t.integer  "y",               :default => 0
    t.boolean  "is_group",        :default => false
  end

  create_table "patterns", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "ontology_id"
    t.string   "type"
    t.integer  "pattern_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "patterns", ["ontology_id"], :name => "index_patterns_on_ontology_id"
  add_index "patterns", ["pattern_id"], :name => "index_patterns_on_pattern_id"

  create_table "repositories", :force => true do |t|
    t.string  "name"
    t.string  "db_name"
    t.string  "db_username"
    t.string  "db_password"
    t.string  "host"
    t.integer "port"
    t.text    "description"
    t.integer "ontology_id"
    t.string  "type"
    t.integer "rdbms_type_cd"
  end

  add_index "repositories", ["ontology_id"], :name => "index_repositories_on_ontology_id"

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

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], :name => "taggings_idx", :unique => true

  create_table "tags", :force => true do |t|
    t.string  "name"
    t.integer "taggings_count", :default => 0
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "type_expressions", :force => true do |t|
    t.string   "operator"
    t.string   "rdf_type"
    t.integer  "pattern_element_id"
    t.string   "ancestry"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "type_expressions", ["ancestry"], :name => "index_type_expressions_on_ancestry"

end
