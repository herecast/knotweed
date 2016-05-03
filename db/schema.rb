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

ActiveRecord::Schema.define(version: 20160502180554) do

  create_table "annotation_reports", force: :cascade do |t|
    t.integer  "content_id",    limit: 4
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "name",          limit: 255
    t.text     "description",   limit: 65535
    t.text     "json_response", limit: 4294967295
    t.integer  "repository_id", limit: 4
  end

  create_table "annotations", force: :cascade do |t|
    t.integer  "annotation_report_id", limit: 4
    t.string   "annotation_id",        limit: 255
    t.boolean  "accepted"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "startnode",            limit: 255
    t.string   "endnode",              limit: 255
    t.string   "annotation_type",      limit: 255
    t.boolean  "is_generated"
    t.string   "lookup_class",         limit: 255
    t.string   "token_feature",        limit: 255
    t.string   "recognized_class",     limit: 255
    t.string   "annotated_string",     limit: 255
    t.string   "instance",             limit: 255
    t.text     "edges",                limit: 65535
    t.boolean  "is_trusted"
    t.string   "rule",                 limit: 255
  end

  create_table "business_categories", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.string   "icon_class",  limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "source",      limit: 255
    t.integer  "source_id",   limit: 4
  end

  add_index "business_categories", ["source", "source_id"], name: "index_business_categories_on_source_and_source_id", using: :btree

  create_table "business_categories_business_categories", id: false, force: :cascade do |t|
    t.integer "parent_id", limit: 4
    t.integer "child_id",  limit: 4
  end

  add_index "business_categories_business_categories", ["parent_id", "child_id"], name: "business_categories_index", unique: true, using: :btree

  create_table "business_categories_business_profiles", id: false, force: :cascade do |t|
    t.integer "business_category_id", limit: 4
    t.integer "business_profile_id",  limit: 4
  end

  create_table "business_feedbacks", force: :cascade do |t|
    t.integer  "created_by",          limit: 4
    t.integer  "updated_by",          limit: 4
    t.integer  "business_profile_id", limit: 4
    t.boolean  "satisfaction"
    t.boolean  "cleanliness"
    t.boolean  "price"
    t.boolean  "recommend"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "business_locations", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.string   "address",             limit: 255
    t.string   "phone",               limit: 255
    t.string   "email",               limit: 255
    t.text     "hours",               limit: 65535
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.integer  "organization_id",     limit: 4
    t.float    "latitude",            limit: 24
    t.float    "longitude",           limit: 24
    t.string   "venue_url",           limit: 255
    t.boolean  "locate_include_name",                              default: false
    t.string   "city",                limit: 255
    t.string   "state",               limit: 255
    t.string   "zip",                 limit: 255
    t.string   "status",              limit: 255
    t.integer  "created_by",          limit: 4
    t.integer  "updated_by",          limit: 4
    t.decimal  "service_radius",                    precision: 10
  end

  add_index "business_locations", ["created_by"], name: "index_business_locations_on_created_by", using: :btree
  add_index "business_locations", ["name"], name: "index_business_locations_on_name", using: :btree

  create_table "business_profiles", force: :cascade do |t|
    t.integer  "business_location_id",      limit: 4
    t.boolean  "has_retail_location",                                  default: true
    t.datetime "created_at",                                                           null: false
    t.datetime "updated_at",                                                           null: false
    t.string   "source",                    limit: 255
    t.string   "source_id",                 limit: 255
    t.decimal  "existence",                             precision: 10
    t.integer  "feedback_count",            limit: 4,                  default: 0
    t.float    "feedback_recommend_avg",    limit: 24,                 default: 0.0
    t.float    "feedback_price_avg",        limit: 24,                 default: 0.0
    t.float    "feedback_satisfaction_avg", limit: 24,                 default: 0.0
    t.float    "feedback_cleanliness_avg",  limit: 24,                 default: 0.0
    t.boolean  "archived",                                             default: false
  end

  add_index "business_profiles", ["existence"], name: "index_business_profiles_on_existence", using: :btree
  add_index "business_profiles", ["source", "source_id"], name: "index_business_profiles_on_source_and_source_id", using: :btree

  create_table "categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "channel_id", limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "categories", ["name"], name: "index_categories_on_name", using: :btree

  create_table "category_corrections", force: :cascade do |t|
    t.integer  "content_id",   limit: 4
    t.string   "old_category", limit: 255
    t.string   "new_category", limit: 255
    t.string   "user_email",   limit: 255
    t.string   "title",        limit: 255
    t.text     "content_body", limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "category_corrections", ["content_id"], name: "index_category_corrections_on_content_id", using: :btree

  create_table "channels", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "comments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "consumer_apps", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "uri",           limit: 255
    t.integer  "repository_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "consumer_apps", ["uri"], name: "index_consumer_apps_on_uri", unique: true, using: :btree

  create_table "consumer_apps_import_jobs", id: false, force: :cascade do |t|
    t.integer "consumer_app_id", limit: 4
    t.integer "import_job_id",   limit: 4
  end

  create_table "consumer_apps_messages", id: false, force: :cascade do |t|
    t.integer "message_id",      limit: 4
    t.integer "consumer_app_id", limit: 4
  end

  add_index "consumer_apps_messages", ["consumer_app_id", "message_id"], name: "consumer_apps_messages_joins_index", unique: true, using: :btree

  create_table "consumer_apps_organizations", id: false, force: :cascade do |t|
    t.integer "consumer_app_id", limit: 4, null: false
    t.integer "organization_id", limit: 4, null: false
  end

  add_index "consumer_apps_organizations", ["consumer_app_id", "organization_id"], name: "consumer_app_publication_index", using: :btree

  create_table "consumer_apps_wufoo_forms", id: false, force: :cascade do |t|
    t.integer "consumer_app_id", limit: 4
    t.integer "wufoo_form_id",   limit: 4
  end

  add_index "consumer_apps_wufoo_forms", ["consumer_app_id", "wufoo_form_id"], name: "consumer_apps_wufoo_forms_joins_index", unique: true, using: :btree

  create_table "contacts", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.string   "phone",        limit: 255
    t.string   "email",        limit: 255
    t.text     "notes",        limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "contact_type", limit: 255
    t.text     "address",      limit: 65535
  end

  create_table "contacts_organizations", force: :cascade do |t|
    t.integer "contact_id",      limit: 4
    t.integer "organization_id", limit: 4
  end

  create_table "content_categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "parent_id",  limit: 4
  end

  create_table "content_categories_organizations", id: false, force: :cascade do |t|
    t.integer "content_category_id", limit: 4
    t.integer "organization_id",     limit: 4
  end

  add_index "content_categories_organizations", ["content_category_id", "organization_id"], name: "index_on_content_category_id_and_publication_id", using: :btree

  create_table "content_promotion_banner_impressions", force: :cascade do |t|
    t.integer  "content_id",          limit: 4
    t.integer  "promotion_banner_id", limit: 4
    t.integer  "display_count",       limit: 4,   default: 1
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "select_method",       limit: 255
    t.float    "select_score",        limit: 24
  end

  add_index "content_promotion_banner_impressions", ["content_id", "promotion_banner_id"], name: "content_promotion_banner_impression", unique: true, using: :btree

  create_table "content_reports", force: :cascade do |t|
    t.integer  "content_id",               limit: 4
    t.datetime "report_date"
    t.integer  "view_count",               limit: 4
    t.integer  "banner_click_count",       limit: 4
    t.integer  "comment_count",            limit: 4
    t.integer  "total_view_count",         limit: 4
    t.integer  "total_banner_click_count", limit: 4
    t.integer  "total_comment_count",      limit: 4
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "content_sets", force: :cascade do |t|
    t.string   "import_method",         limit: 255
    t.text     "import_method_details", limit: 65535
    t.integer  "organization_id",       limit: 4
    t.string   "name",                  limit: 255
    t.text     "description",           limit: 65535
    t.text     "notes",                 limit: 65535
    t.string   "status",                limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "ongoing"
    t.string   "format",                limit: 255
    t.string   "publishing_frequency",  limit: 255
    t.text     "developer_notes",       limit: 65535
    t.integer  "import_priority",       limit: 4,     default: 1
    t.string   "import_url_path",       limit: 255
  end

  create_table "contents", force: :cascade do |t|
    t.string   "title",                     limit: 255
    t.string   "subtitle",                  limit: 255
    t.string   "authors",                   limit: 255
    t.text     "raw_content",               limit: 65535
    t.integer  "issue_id",                  limit: 4
    t.integer  "import_location_id",        limit: 4
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.string   "copyright",                 limit: 255
    t.string   "guid",                      limit: 255
    t.datetime "pubdate"
    t.string   "source_category",           limit: 255
    t.string   "topics",                    limit: 255
    t.string   "url",                       limit: 255
    t.string   "origin",                    limit: 255
    t.string   "language",                  limit: 255
    t.string   "page",                      limit: 255
    t.string   "authoremail",               limit: 255
    t.integer  "organization_id",           limit: 4
    t.boolean  "quarantine",                              default: false
    t.string   "doctype",                   limit: 255
    t.datetime "timestamp"
    t.string   "contentsource",             limit: 255
    t.integer  "import_record_id",          limit: 4
    t.string   "source_content_id",         limit: 255
    t.integer  "parent_id",                 limit: 4
    t.integer  "content_category_id",       limit: 4
    t.boolean  "category_reviewed",                       default: false
    t.boolean  "has_event_calendar",                      default: false
    t.integer  "channelized_content_id",    limit: 4
    t.boolean  "published",                               default: false
    t.string   "channel_type",              limit: 255
    t.integer  "channel_id",                limit: 4
    t.integer  "root_content_category_id",  limit: 4
    t.integer  "view_count",                limit: 4,     default: 0
    t.integer  "comment_count",             limit: 4,     default: 0
    t.integer  "commenter_count",           limit: 4,     default: 0
    t.integer  "created_by",                limit: 4
    t.integer  "updated_by",                limit: 4
    t.integer  "banner_click_count",        limit: 4,     default: 0
    t.text     "similar_content_overrides", limit: 65535
    t.integer  "banner_ad_override",        limit: 4
    t.integer  "root_parent_id",            limit: 4
    t.boolean  "my_town_only",                            default: false
  end

  add_index "contents", ["authoremail"], name: "index_contents_on_authoremail", using: :btree
  add_index "contents", ["authors"], name: "authors", using: :btree
  add_index "contents", ["channel_id"], name: "index_contents_on_channel_id", using: :btree
  add_index "contents", ["channel_type"], name: "index_contents_on_channel_type", using: :btree
  add_index "contents", ["channelized_content_id"], name: "index_contents_on_channelized_content_id", using: :btree
  add_index "contents", ["content_category_id"], name: "content_category_id", using: :btree
  add_index "contents", ["created_by"], name: "index_contents_on_created_by", using: :btree
  add_index "contents", ["guid"], name: "guid", using: :btree
  add_index "contents", ["import_location_id"], name: "location_id", using: :btree
  add_index "contents", ["import_record_id"], name: "import_record_id", using: :btree
  add_index "contents", ["organization_id"], name: "source_id", using: :btree
  add_index "contents", ["parent_id"], name: "index_contents_on_parent_id", using: :btree
  add_index "contents", ["pubdate"], name: "pubdate", using: :btree
  add_index "contents", ["published"], name: "index_contents_on_published", using: :btree
  add_index "contents", ["root_content_category_id"], name: "index_contents_on_root_content_category_id", using: :btree
  add_index "contents", ["root_parent_id"], name: "index_contents_on_root_parent_id", using: :btree
  add_index "contents", ["source_category"], name: "categories", using: :btree
  add_index "contents", ["title"], name: "title", using: :btree

  create_table "contents_locations", id: false, force: :cascade do |t|
    t.integer "content_id",  limit: 4
    t.integer "location_id", limit: 4
  end

  add_index "contents_locations", ["content_id", "location_id"], name: "index_contents_locations_on_content_id_and_location_id", using: :btree
  add_index "contents_locations", ["content_id"], name: "index_contents_locations_on_content_id", using: :btree
  add_index "contents_locations", ["location_id", "content_id"], name: "index_contents_locations_on_location_id_and_content_id", using: :btree
  add_index "contents_locations", ["location_id"], name: "index_contents_locations_on_location_id", using: :btree

  create_table "contents_publish_records", id: false, force: :cascade do |t|
    t.integer "content_id",        limit: 4
    t.integer "publish_record_id", limit: 4
  end

  create_table "contents_repositories", id: false, force: :cascade do |t|
    t.integer "content_id",    limit: 4, null: false
    t.integer "repository_id", limit: 4, null: false
  end

  add_index "contents_repositories", ["content_id", "repository_id"], name: "index_contents_repositories_on_content_id_and_repository_id", using: :btree
  add_index "contents_repositories", ["repository_id", "content_id"], name: "index_contents_repositories_on_repository_id_and_content_id", using: :btree

  create_table "data_contexts", force: :cascade do |t|
    t.string   "context",    limit: 255
    t.boolean  "loaded",                 default: false
    t.datetime "last_load"
    t.boolean  "archived",               default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  create_table "datasets", force: :cascade do |t|
    t.integer  "data_context_id", limit: 4
    t.string   "name",            limit: 255
    t.string   "description",     limit: 255
    t.string   "realm",           limit: 255
    t.string   "model_type",      limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "event_instances", force: :cascade do |t|
    t.integer  "event_id",             limit: 4
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "subtitle_override",    limit: 255
    t.text     "description_override", limit: 65535
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "presenter_name",       limit: 255
    t.integer  "schedule_id",          limit: 4
  end

  add_index "event_instances", ["end_date"], name: "index_event_instances_on_end_date", using: :btree
  add_index "event_instances", ["event_id"], name: "index_event_instances_on_event_id", using: :btree
  add_index "event_instances", ["start_date"], name: "index_event_instances_on_start_date", using: :btree

  create_table "events", force: :cascade do |t|
    t.string   "event_type",            limit: 255
    t.integer  "venue_id",              limit: 4
    t.string   "cost",                  limit: 255
    t.string   "event_url",             limit: 255
    t.string   "sponsor",               limit: 255
    t.string   "sponsor_url",           limit: 255
    t.text     "links",                 limit: 65535
    t.boolean  "featured"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "contact_phone",         limit: 255
    t.string   "contact_email",         limit: 255
    t.string   "cost_type",             limit: 255
    t.string   "event_category",        limit: 255
    t.boolean  "social_enabled",                      default: false
    t.datetime "registration_deadline"
    t.string   "registration_url",      limit: 255
    t.string   "registration_phone",    limit: 255
    t.string   "registration_email",    limit: 255
  end

  add_index "events", ["featured"], name: "index_events_on_featured", using: :btree
  add_index "events", ["venue_id"], name: "events_on_venue_id_index", using: :btree
  add_index "events", ["venue_id"], name: "index_events_on_venue_id", using: :btree

  create_table "images", force: :cascade do |t|
    t.string   "caption",        limit: 255
    t.string   "credit",         limit: 255
    t.string   "image",          limit: 255
    t.string   "imageable_type", limit: 255
    t.integer  "imageable_id",   limit: 4
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "source_url",     limit: 400
    t.boolean  "primary",                    default: false
  end

  add_index "images", ["imageable_type", "imageable_id"], name: "index_images_on_imageable_type_and_imageable_id", using: :btree

  create_table "import_jobs", force: :cascade do |t|
    t.integer  "parser_id",             limit: 4
    t.string   "name",                  limit: 255
    t.text     "config",                limit: 65535
    t.string   "source_path",           limit: 255
    t.string   "job_type",              limit: 255
    t.integer  "organization_id",       limit: 4
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "status",                limit: 255
    t.integer  "frequency",             limit: 4,     default: 0
    t.boolean  "archive",                             default: false, null: false
    t.integer  "content_set_id",        limit: 4
    t.datetime "run_at"
    t.boolean  "stop_loop",                           default: true
    t.boolean  "automatically_publish",               default: false
    t.integer  "repository_id",         limit: 4
    t.string   "publish_method",        limit: 255
  end

  create_table "import_locations", force: :cascade do |t|
    t.integer  "parent_id",      limit: 4,   default: 0
    t.integer  "region_id",      limit: 4,   default: 0
    t.string   "city",           limit: 255
    t.string   "state",          limit: 255
    t.string   "zip",            limit: 255
    t.string   "country",        limit: 128
    t.string   "link_name",      limit: 255
    t.string   "link_name_full", limit: 255
    t.integer  "status",         limit: 4,   default: 0
    t.string   "usgs_id",        limit: 128
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "import_locations", ["city"], name: "city", using: :btree
  add_index "import_locations", ["link_name"], name: "link_name", using: :btree
  add_index "import_locations", ["link_name_full"], name: "link_name_full", using: :btree
  add_index "import_locations", ["state"], name: "state", using: :btree
  add_index "import_locations", ["status"], name: "status", using: :btree
  add_index "import_locations", ["usgs_id"], name: "usgs_id", using: :btree

  create_table "import_records", force: :cascade do |t|
    t.integer  "import_job_id",  limit: 4
    t.integer  "items_imported", limit: 4, default: 0
    t.integer  "failures",       limit: 4, default: 0
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "filtered",       limit: 4, default: 0
  end

  create_table "issues", force: :cascade do |t|
    t.string   "issue_edition",      limit: 255
    t.integer  "organization_id",    limit: 4
    t.string   "copyright",          limit: 255
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "import_location_id", limit: 4
    t.datetime "publication_date"
  end

  create_table "listservs", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.string   "reverse_publish_email", limit: 255
    t.string   "import_name",           limit: 255
    t.boolean  "active"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  create_table "listservs_locations", id: false, force: :cascade do |t|
    t.integer "listserv_id", limit: 4
    t.integer "location_id", limit: 4
  end

  create_table "locations", force: :cascade do |t|
    t.string   "zip",             limit: 255
    t.string   "city",            limit: 255
    t.string   "state",           limit: 255
    t.string   "county",          limit: 255
    t.string   "lat",             limit: 255
    t.string   "long",            limit: 255
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.boolean  "consumer_active",             default: false
  end

  create_table "locations_locations", id: false, force: :cascade do |t|
    t.integer "parent_id", limit: 4
    t.integer "child_id",  limit: 4
  end

  add_index "locations_locations", ["child_id", "parent_id"], name: "index_locations_locations_on_child_id_and_parent_id", using: :btree
  add_index "locations_locations", ["child_id"], name: "index_locations_locations_on_child_id", using: :btree
  add_index "locations_locations", ["parent_id", "child_id"], name: "index_locations_locations_on_parent_id_and_child_id", using: :btree
  add_index "locations_locations", ["parent_id"], name: "index_locations_locations_on_parent_id", using: :btree

  create_table "locations_organizations", force: :cascade do |t|
    t.integer  "location_id",     limit: 4
    t.integer  "organization_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "locations_organizations", ["location_id", "organization_id"], name: "index_locations_publications_on_location_id_and_publication_id", using: :btree
  add_index "locations_organizations", ["location_id"], name: "index_locations_publications_on_location_id", using: :btree
  add_index "locations_organizations", ["organization_id", "location_id"], name: "index_locations_publications_on_publication_id_and_location_id", using: :btree
  add_index "locations_organizations", ["organization_id"], name: "index_locations_publications_on_publication_id", using: :btree

  create_table "market_posts", force: :cascade do |t|
    t.string   "cost",                     limit: 255
    t.string   "contact_phone",            limit: 255
    t.string   "contact_email",            limit: 255
    t.string   "contact_url",              limit: 255
    t.string   "locate_name",              limit: 255
    t.string   "locate_address",           limit: 255
    t.float    "latitude",                 limit: 24
    t.float    "longitude",                limit: 24
    t.boolean  "locate_include_name"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "status",                   limit: 255
    t.string   "preferred_contact_method", limit: 255
  end

  create_table "messages", force: :cascade do |t|
    t.integer  "created_by_id", limit: 4
    t.string   "controller",    limit: 255
    t.string   "action",        limit: 255
    t.datetime "start_date"
    t.datetime "end_date"
    t.text     "content",       limit: 65535
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "notifiers", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.integer  "notifyable_id",   limit: 4
    t.string   "notifyable_type", limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "logo",                  limit: 255
    t.integer  "organization_id",       limit: 4
    t.string   "website",               limit: 255
    t.text     "notes",                 limit: 65535
    t.integer  "parent_id",             limit: 4
    t.string   "category_override",     limit: 255
    t.string   "org_type",              limit: 255
    t.boolean  "display_attributes",                  default: false
    t.string   "reverse_publish_email", limit: 255
    t.boolean  "can_reverse_publish",                 default: false
    t.boolean  "can_publish_news",                    default: false
    t.string   "subscribe_url",         limit: 255
    t.text     "description",           limit: 65535
  end

  add_index "organizations", ["name"], name: "index_publications_on_name", unique: true, using: :btree

  create_table "parameters", force: :cascade do |t|
    t.integer  "parser_id",  limit: 4
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "parsers", force: :cascade do |t|
    t.string   "filename",    limit: 255
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "promotion_banner_reports", force: :cascade do |t|
    t.integer  "promotion_banner_id",    limit: 4
    t.datetime "report_date"
    t.integer  "impression_count",       limit: 4
    t.integer  "click_count",            limit: 4
    t.integer  "total_impression_count", limit: 4
    t.integer  "total_click_count",      limit: 4
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  create_table "promotion_banners", force: :cascade do |t|
    t.string   "banner_image",           limit: 255
    t.string   "redirect_url",           limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.date     "campaign_start"
    t.date     "campaign_end"
    t.integer  "max_impressions",        limit: 4
    t.integer  "impression_count",       limit: 4,   default: 0
    t.integer  "click_count",            limit: 4,   default: 0
    t.integer  "daily_max_impressions",  limit: 4
    t.boolean  "boost",                              default: false
    t.integer  "daily_impression_count", limit: 4,   default: 0
  end

  create_table "promotion_listservs", force: :cascade do |t|
    t.integer  "listserv_id", limit: 4
    t.datetime "sent_at"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "promotions", force: :cascade do |t|
    t.boolean  "active"
    t.string   "banner",          limit: 255
    t.integer  "organization_id", limit: 4
    t.integer  "content_id",      limit: 4
    t.text     "description",     limit: 65535
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "promotable_id",   limit: 4
    t.string   "promotable_type", limit: 255
    t.boolean  "paid",                          default: false
    t.integer  "created_by",      limit: 4
    t.integer  "updated_by",      limit: 4
  end

  add_index "promotions", ["content_id"], name: "index_promotions_on_content_id", using: :btree
  add_index "promotions", ["created_by"], name: "index_promotions_on_created_by", using: :btree
  add_index "promotions", ["organization_id"], name: "index_promotions_on_publication_id", using: :btree

  create_table "publish_jobs", force: :cascade do |t|
    t.text     "query_params",    limit: 65535
    t.integer  "organization_id", limit: 4
    t.string   "status",          limit: 255
    t.integer  "frequency",       limit: 4,     default: 0
    t.string   "publish_method",  limit: 255
    t.boolean  "archive",                       default: false
    t.string   "error",           limit: 255
    t.string   "name",            limit: 255
    t.text     "description",     limit: 65535
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.text     "file_archive",    limit: 65535
    t.datetime "run_at"
  end

  create_table "publish_records", force: :cascade do |t|
    t.integer  "publish_job_id",  limit: 4
    t.integer  "items_published", limit: 4, default: 0
    t.integer  "failures",        limit: 4, default: 0
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "publish_records", ["publish_job_id"], name: "index_publish_records_on_publish_job_id", using: :btree

  create_table "repositories", force: :cascade do |t|
    t.string   "name",                    limit: 255
    t.string   "dsp_endpoint",            limit: 255
    t.string   "sesame_endpoint",         limit: 255
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "graphdb_endpoint",        limit: 255
    t.string   "annotate_endpoint",       limit: 255
    t.string   "solr_endpoint",           limit: 255
    t.string   "recommendation_endpoint", limit: 255
  end

  create_table "rewrites", force: :cascade do |t|
    t.string   "source",      limit: 255
    t.string   "destination", limit: 255
    t.integer  "created_by",  limit: 4
    t.integer  "updated_by",  limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "rewrites", ["created_by"], name: "index_rewrites_on_created_by", using: :btree
  add_index "rewrites", ["source"], name: "index_rewrites_on_source", unique: true, using: :btree
  add_index "rewrites", ["updated_at"], name: "index_rewrites_on_updated_at", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "resource_id",   limit: 4
    t.string   "resource_type", limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "schedules", force: :cascade do |t|
    t.text     "recurrence",           limit: 65535
    t.integer  "event_id",             limit: 4
    t.text     "description_override", limit: 65535
    t.string   "subtitle_override",    limit: 255
    t.string   "presenter_name",       limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "user_wufoo_forms", id: false, force: :cascade do |t|
    t.integer "user_id",       limit: 4
    t.integer "wufoo_form_id", limit: 4
  end

  add_index "user_wufoo_forms", ["user_id", "wufoo_form_id"], name: "index_user_wufoo_forms_on_user_id_and_wufoo_form_id", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",         null: false
    t.string   "encrypted_password",     limit: 255, default: "",         null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.string   "name",                   limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.integer  "default_repository_id",  limit: 4
    t.datetime "nda_agreed_at"
    t.boolean  "agreed_to_nda",                      default: false
    t.boolean  "admin",                              default: false
    t.string   "contact_phone",          limit: 255
    t.string   "contact_email",          limit: 255
    t.string   "contact_url",            limit: 255
    t.integer  "location_id",            limit: 4
    t.string   "test_group",             limit: 255, default: "consumer"
    t.boolean  "muted",                              default: false
    t.string   "authentication_token",   limit: 255
    t.string   "avatar",                 limit: 255
    t.string   "public_id",              limit: 255
    t.boolean  "skip_analytics",                     default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["public_id"], name: "index_users_on_public_id", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.integer "role_id", limit: 4
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "wufoo_forms", force: :cascade do |t|
    t.string   "form_hash",      limit: 255
    t.string   "email_field",    limit: 255
    t.string   "name",           limit: 255
    t.text     "call_to_action", limit: 65535
    t.string   "controller",     limit: 255
    t.string   "action",         limit: 255
    t.boolean  "active",                       default: true
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "page_url_field", limit: 255
  end

  add_index "wufoo_forms", ["controller", "action", "active"], name: "index_wufoo_forms_on_controller_and_action_and_active", unique: true, using: :btree

end
