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

ActiveRecord::Schema.define(:version => 20140711211610) do

  create_table "USGS_pop", :force => true do |t|
    t.integer "FEATURE_ID"
    t.string  "FEATURE_NAME",    :limit => 120
    t.string  "FEATURE_CLASS",   :limit => 50
    t.string  "STATE_ALPHA",     :limit => 2
    t.string  "STATE_NUMERIC",   :limit => 2
    t.string  "COUNTY_NAME",     :limit => 100
    t.string  "COUNTY_NUMERIC",  :limit => 3
    t.string  "PRIMARY_LAT_DMS", :limit => 7
    t.string  "PRIM_LONG_DMS",   :limit => 8
    t.decimal "PRIM_LAT_DEC",                   :precision => 11, :scale => 7
    t.decimal "PRIM_LONG_DEC",                  :precision => 12, :scale => 7
    t.string  "SOURCE_LAT_DMS",  :limit => 7
    t.string  "SOURCE_LONG_DMS", :limit => 8
    t.decimal "SOURCE_LAT_DEC",                 :precision => 11, :scale => 7
    t.decimal "SOURCE_LONG_DEC",                :precision => 12, :scale => 7
    t.integer "ELEV_IN_M"
    t.integer "ELEV_IN_FT"
    t.string  "MAP_NAME",        :limit => 100
    t.date    "DATE_CREATED"
    t.date    "DATE_EDITED"
  end

  add_index "USGS_pop", ["FEATURE_ID"], :name => "FEATURE_ID"
  add_index "USGS_pop", ["FEATURE_NAME"], :name => "FEATURE_NAME"
  add_index "USGS_pop", ["STATE_ALPHA"], :name => "STATE_ALPHA"

  create_table "annotation_reports", :force => true do |t|
    t.integer  "content_id"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.string   "name"
    t.text     "description"
    t.text     "json_response", :limit => 2147483647
    t.integer  "repository_id"
  end

  create_table "annotations", :force => true do |t|
    t.integer  "annotation_report_id"
    t.string   "annotation_id"
    t.boolean  "accepted"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "startnode"
    t.string   "endnode"
    t.string   "annotation_type"
    t.boolean  "is_generated"
    t.string   "lookup_class"
    t.string   "token_feature"
    t.string   "recognized_class"
    t.string   "annotated_string"
    t.string   "instance"
    t.text     "edges"
    t.boolean  "is_trusted"
    t.string   "rule"
  end

  create_table "business_locations", :force => true do |t|
    t.string   "name"
    t.integer  "organization_id"
    t.string   "address"
    t.string   "phone"
    t.string   "email"
    t.string   "hours"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.integer  "channel_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "categories", ["name"], :name => "index_categories_on_name"

  create_table "category_corrections", :force => true do |t|
    t.integer  "content_id"
    t.string   "old_category"
    t.string   "new_category"
    t.string   "user_email"
    t.string   "title"
    t.text     "content_body"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "channel_map", :force => true do |t|
    t.integer   "channel_id"
    t.text      "category"
    t.timestamp "created_at", :null => false
  end

  add_index "channel_map", ["channel_id"], :name => "channel_id"

  create_table "channels", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "contacts", :force => true do |t|
    t.string   "name"
    t.string   "phone"
    t.string   "email"
    t.text     "notes"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "contact_type"
    t.text     "address"
  end

  create_table "contacts_organizations", :force => true do |t|
    t.integer "contact_id"
    t.integer "organization_id"
  end

  create_table "contacts_publications", :force => true do |t|
    t.integer  "contact_id"
    t.integer  "publication_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "content_sets", :force => true do |t|
    t.string   "import_method"
    t.text     "import_method_details"
    t.integer  "publication_id"
    t.string   "name"
    t.text     "description"
    t.text     "notes"
    t.string   "status"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "ongoing"
    t.string   "format"
    t.string   "publishing_frequency"
    t.text     "developer_notes"
    t.integer  "import_priority",       :default => 1
    t.string   "import_url_path"
  end

  create_table "contents", :force => true do |t|
    t.string   "title"
    t.string   "subtitle"
    t.string   "authors"
    t.text     "content"
    t.integer  "issue_id"
    t.integer  "import_location_id"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.string   "copyright"
    t.string   "guid"
    t.datetime "pubdate"
    t.string   "categories"
    t.string   "topics"
    t.text     "summary"
    t.string   "url"
    t.string   "origin"
    t.string   "mimetype"
    t.string   "language"
    t.string   "page"
    t.string   "wordcount"
    t.string   "authoremail"
    t.integer  "source_id"
    t.string   "file"
    t.boolean  "quarantine",                        :default => false
    t.string   "doctype"
    t.datetime "timestamp"
    t.string   "contentsource"
    t.integer  "import_record_id"
    t.string   "source_content_id"
    t.string   "image",              :limit => 400
    t.integer  "parent_id"
  end

  add_index "contents", ["authors"], :name => "authors"
  add_index "contents", ["categories"], :name => "categories"
  add_index "contents", ["guid"], :name => "guid"
  add_index "contents", ["import_location_id"], :name => "location_id"
  add_index "contents", ["import_record_id"], :name => "import_record_id"
  add_index "contents", ["parent_id"], :name => "index_contents_on_parent_id"
  add_index "contents", ["pubdate"], :name => "pubdate"
  add_index "contents", ["source_id"], :name => "source_id"
  add_index "contents", ["title"], :name => "title"

  create_table "contents_NT", :force => true do |t|
    t.string   "title"
    t.string   "subtitle"
    t.string   "authors"
    t.string   "subject"
    t.text     "content"
    t.integer  "issue_id"
    t.integer  "location_id"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "reviewed",       :default => false
    t.integer  "lupdate_by"
    t.integer  "publication_id"
  end

  create_table "contents_publish_records", :id => false, :force => true do |t|
    t.integer "content_id"
    t.integer "publish_record_id"
  end

  create_table "contents_repositories", :id => false, :force => true do |t|
    t.integer "content_id",    :null => false
    t.integer "repository_id", :null => false
  end

  add_index "contents_repositories", ["content_id", "repository_id"], :name => "index_contents_repositories_on_content_id_and_repository_id"

  create_table "countries", :force => true do |t|
    t.string  "country_name"
    t.string  "capital_city"
    t.string  "continent",    :limit => 10
    t.string  "alpha2",       :limit => 10
    t.string  "alpha3",       :limit => 10
    t.integer "numeric"
    t.string  "flps",         :limit => 10
    t.integer "area_km"
    t.integer "population"
  end

  add_index "countries", ["capital_city"], :name => "capital_city"
  add_index "countries", ["country_name"], :name => "country_name"

  create_table "data_contexts", :force => true do |t|
    t.string   "context"
    t.boolean  "loaded",     :default => false
    t.datetime "last_load"
    t.boolean  "archived",   :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "datasets", :force => true do |t|
    t.integer  "data_context_id"
    t.string   "name"
    t.string   "description"
    t.string   "realm"
    t.string   "model_type"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
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

  create_table "images", :force => true do |t|
    t.string   "caption"
    t.string   "credit"
    t.string   "image"
    t.string   "imageable_type"
    t.integer  "imageable_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.string   "source_url",     :limit => 400
  end

  create_table "import_jobs", :force => true do |t|
    t.integer  "parser_id"
    t.string   "name"
    t.text     "config"
    t.string   "source_path"
    t.string   "type"
    t.integer  "organization_id"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "status"
    t.integer  "frequency",       :default => 0
    t.boolean  "archive",         :default => false, :null => false
    t.integer  "content_set_id"
  end

  create_table "import_locations", :force => true do |t|
    t.integer  "parent_id",                     :default => 0
    t.integer  "region_id",                     :default => 0
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country",        :limit => 128
    t.string   "link_name"
    t.string   "link_name_full"
    t.integer  "status",                        :default => 0
    t.string   "usgs_id",        :limit => 128
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
  end

  add_index "import_locations", ["city"], :name => "city"
  add_index "import_locations", ["link_name"], :name => "link_name"
  add_index "import_locations", ["link_name_full"], :name => "link_name_full"
  add_index "import_locations", ["state"], :name => "state"
  add_index "import_locations", ["status"], :name => "status"
  add_index "import_locations", ["usgs_id"], :name => "usgs_id"

  create_table "import_records", :force => true do |t|
    t.integer  "import_job_id"
    t.integer  "items_imported", :default => 0
    t.integer  "failures",       :default => 0
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "issues", :force => true do |t|
    t.string   "issue_edition"
    t.integer  "publication_id"
    t.string   "copyright"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.integer  "import_location_id"
    t.datetime "publication_date"
  end

  create_table "issues_NT", :force => true do |t|
    t.integer  "publication_id"
    t.date     "publication_date"
    t.integer  "location_id"
    t.string   "issue_edition"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "copyright"
  end

  create_table "locations", :force => true do |t|
    t.string   "zip"
    t.string   "city"
    t.string   "state"
    t.string   "county"
    t.string   "lat"
    t.string   "long"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "locations_bad", :force => true do |t|
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "action",     :limit => 128
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "locations_bad", ["city"], :name => "city"

  create_table "locations_old", :force => true do |t|
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "parent_id"
    t.integer  "region_id"
    t.string   "country",        :limit => 128
    t.string   "link_name"
    t.string   "link_name_full"
    t.integer  "status",         :limit => 1,   :default => 1, :null => false
    t.string   "usgs_id",        :limit => 128
  end

  add_index "locations_old", ["city"], :name => "city"
  add_index "locations_old", ["link_name"], :name => "index_locations_on_link_name"
  add_index "locations_old", ["state"], :name => "index_locations_on_state"
  add_index "locations_old", ["status"], :name => "index_locations_on_status"
  add_index "locations_old", ["usgs_id"], :name => "index_locations_on_usgs_id"

  create_table "locations_publications", :force => true do |t|
    t.integer  "location_id"
    t.integer  "publication_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "locations_sav", :force => true do |t|
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "locations_sav", ["city"], :name => "city"

  create_table "notifiers", :force => true do |t|
    t.integer  "user_id"
    t.integer  "notifyable_id"
    t.string   "notifyable_type"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "organizations", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "org_type"
    t.text     "notes"
    t.string   "tagline"
    t.text     "links"
    t.text     "social_media"
    t.text     "general"
  end

  create_table "parameters", :force => true do |t|
    t.integer  "parser_id"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "parsers", :force => true do |t|
    t.string   "filename"
    t.integer  "organization_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "publications", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "logo"
    t.integer  "organization_id"
    t.string   "website"
    t.string   "publishing_frequency"
    t.text     "notes"
    t.integer  "parent_id"
    t.string   "category_override"
  end

  create_table "publish_jobs", :force => true do |t|
    t.text     "query_params"
    t.integer  "organization_id"
    t.string   "status"
    t.integer  "frequency",       :default => 0
    t.string   "publish_method"
    t.boolean  "archive",         :default => false
    t.string   "error"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.text     "file_archive"
  end

  create_table "publish_records", :force => true do |t|
    t.integer  "publish_job_id"
    t.integer  "items_published", :default => 0
    t.integer  "failures",        :default => 0
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  add_index "publish_records", ["publish_job_id"], :name => "index_publish_records_on_publish_job_id"

  create_table "regions", :force => true do |t|
    t.string   "region_name"
    t.string   "description"
    t.text     "zipcodes"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "regions", ["region_name"], :name => "region_name"

  create_table "repositories", :force => true do |t|
    t.string   "name"
    t.string   "dsp_endpoint"
    t.string   "sesame_endpoint"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], :name => "index_roles_on_name_and_resource_type_and_resource_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "states", :force => true do |t|
    t.string "statename", :limit => 128
    t.string "abbrev1",   :limit => 128
    t.string "abbrev2",   :limit => 128
    t.string "abbrev3",   :limit => 128
    t.string "capital",   :limit => 128
  end

  add_index "states", ["abbrev1"], :name => "abbreviation"
  add_index "states", ["statename"], :name => "statename"

  create_table "temp_1", :id => false, :force => true do |t|
    t.string "city", :limit => 128
  end

  create_table "triples", :force => true do |t|
    t.integer  "dataset_id"
    t.string   "resource_class"
    t.integer  "resource_id"
    t.string   "resource_text"
    t.string   "predicate"
    t.string   "object_type"
    t.string   "object_class"
    t.integer  "object_resource_id"
    t.string   "object_resource_text"
    t.string   "realm"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "organization_id"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_roles", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], :name => "index_users_roles_on_user_id_and_role_id"

end
