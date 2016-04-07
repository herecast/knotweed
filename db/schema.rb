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

ActiveRecord::Schema.define(version: 20160407212613) do

  create_table "annotation_reports", force: true do |t|
    t.integer  "content_id"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "name"
    t.text     "description"
    t.text     "json_response", limit: 2147483647
    t.integer  "repository_id"
  end

  create_table "annotations", force: true do |t|
    t.integer  "annotation_report_id"
    t.string   "annotation_id"
    t.boolean  "accepted"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
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

  create_table "business_categories", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "icon_class"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "source"
    t.integer  "source_id"
  end

  add_index "business_categories", ["source", "source_id"], name: "index_business_categories_on_source_and_source_id", using: :btree

  create_table "business_categories_business_categories", id: false, force: true do |t|
    t.integer "parent_id"
    t.integer "child_id"
  end

  add_index "business_categories_business_categories", ["parent_id", "child_id"], name: "business_categories_index", unique: true, using: :btree

  create_table "business_categories_business_profiles", id: false, force: true do |t|
    t.integer "business_category_id"
    t.integer "business_profile_id"
  end

  create_table "business_feedbacks", force: true do |t|
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "business_profile_id"
    t.boolean  "satisfaction"
    t.boolean  "cleanliness"
    t.boolean  "price"
    t.boolean  "recommend"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "business_locations", force: true do |t|
    t.string   "name"
    t.string   "address"
    t.string   "phone"
    t.string   "email"
    t.text     "hours"
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.integer  "organization_id"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "venue_url"
    t.boolean  "locate_include_name",                          default: false
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "status"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.decimal  "service_radius",      precision: 10, scale: 0
  end

  add_index "business_locations", ["created_by"], name: "index_business_locations_on_created_by", using: :btree
  add_index "business_locations", ["name"], name: "index_business_locations_on_name", using: :btree

  create_table "business_profiles", force: true do |t|
    t.integer  "business_location_id"
    t.boolean  "has_retail_location",                                default: true
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.string   "source"
    t.string   "source_id"
    t.decimal  "existence",                 precision: 10, scale: 0
    t.integer  "feedback_count",                                     default: 0
    t.float    "feedback_recommend_avg",                             default: 0.0
    t.float    "feedback_price_avg",                                 default: 0.0
    t.float    "feedback_satisfaction_avg",                          default: 0.0
    t.float    "feedback_cleanliness_avg",                           default: 0.0
  end

  add_index "business_profiles", ["existence"], name: "index_business_profiles_on_existence", using: :btree
  add_index "business_profiles", ["source", "source_id"], name: "index_business_profiles_on_source_and_source_id", using: :btree

  create_table "categories", force: true do |t|
    t.string   "name"
    t.integer  "channel_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "categories", ["name"], name: "index_categories_on_name", using: :btree

  create_table "category_corrections", force: true do |t|
    t.integer  "content_id"
    t.string   "old_category"
    t.string   "new_category"
    t.string   "user_email"
    t.string   "title"
    t.text     "content_body"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "category_corrections", ["content_id"], name: "index_category_corrections_on_content_id", using: :btree

  create_table "channels", force: true do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "consumer_apps", force: true do |t|
    t.string   "name"
    t.string   "uri"
    t.integer  "repository_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "consumer_apps", ["uri"], name: "index_consumer_apps_on_uri", unique: true, using: :btree

  create_table "consumer_apps_import_jobs", id: false, force: true do |t|
    t.integer "consumer_app_id"
    t.integer "import_job_id"
  end

  create_table "consumer_apps_messages", id: false, force: true do |t|
    t.integer "message_id"
    t.integer "consumer_app_id"
  end

  add_index "consumer_apps_messages", ["consumer_app_id", "message_id"], name: "consumer_apps_messages_joins_index", unique: true, using: :btree

  create_table "consumer_apps_organizations", id: false, force: true do |t|
    t.integer "consumer_app_id", null: false
    t.integer "organization_id", null: false
  end

  add_index "consumer_apps_organizations", ["consumer_app_id", "organization_id"], name: "consumer_app_publication_index", using: :btree

  create_table "consumer_apps_wufoo_forms", id: false, force: true do |t|
    t.integer "consumer_app_id"
    t.integer "wufoo_form_id"
  end

  add_index "consumer_apps_wufoo_forms", ["consumer_app_id", "wufoo_form_id"], name: "consumer_apps_wufoo_forms_joins_index", unique: true, using: :btree

  create_table "contacts", force: true do |t|
    t.string   "name"
    t.string   "phone"
    t.string   "email"
    t.text     "notes"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "contact_type"
    t.text     "address"
  end

  create_table "contacts_organizations", force: true do |t|
    t.integer "contact_id"
    t.integer "organization_id"
  end

  create_table "content_categories", force: true do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "parent_id"
  end

  create_table "content_categories_organizations", id: false, force: true do |t|
    t.integer "content_category_id"
    t.integer "organization_id"
  end

  add_index "content_categories_organizations", ["content_category_id", "organization_id"], name: "index_on_content_category_id_and_publication_id", using: :btree

  create_table "content_promotion_banner_impressions", force: true do |t|
    t.integer  "content_id"
    t.integer  "promotion_banner_id"
    t.integer  "display_count",       default: 1
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "select_method"
    t.float    "select_score"
  end

  add_index "content_promotion_banner_impressions", ["content_id", "promotion_banner_id"], name: "content_promotion_banner_impression", unique: true, using: :btree

  create_table "content_reports", force: true do |t|
    t.integer  "content_id"
    t.datetime "report_date"
    t.integer  "view_count"
    t.integer  "banner_click_count"
    t.integer  "comment_count"
    t.integer  "total_view_count"
    t.integer  "total_banner_click_count"
    t.integer  "total_comment_count"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "content_sets", force: true do |t|
    t.string   "import_method"
    t.text     "import_method_details"
    t.integer  "organization_id"
    t.string   "name"
    t.text     "description"
    t.text     "notes"
    t.string   "status"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "ongoing"
    t.string   "format"
    t.string   "publishing_frequency"
    t.text     "developer_notes"
    t.integer  "import_priority",       default: 1
    t.string   "import_url_path"
  end

  create_table "contents", force: true do |t|
    t.string   "title"
    t.string   "subtitle"
    t.string   "authors"
    t.text     "raw_content"
    t.integer  "issue_id"
    t.integer  "import_location_id"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "copyright"
    t.string   "guid"
    t.datetime "pubdate"
    t.string   "source_category"
    t.string   "topics"
    t.string   "url"
    t.string   "origin"
    t.string   "language"
    t.string   "page"
    t.string   "authoremail"
    t.integer  "organization_id"
    t.boolean  "quarantine",                default: false
    t.string   "doctype"
    t.datetime "timestamp"
    t.string   "contentsource"
    t.integer  "import_record_id"
    t.string   "source_content_id"
    t.integer  "parent_id"
    t.integer  "content_category_id"
    t.boolean  "category_reviewed",         default: false
    t.boolean  "has_event_calendar",        default: false
    t.integer  "channelized_content_id"
    t.boolean  "published",                 default: false
    t.string   "channel_type"
    t.integer  "channel_id"
    t.integer  "root_content_category_id"
    t.integer  "view_count",                default: 0
    t.integer  "comment_count",             default: 0
    t.integer  "commenter_count",           default: 0
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "banner_click_count",        default: 0
    t.text     "similar_content_overrides"
    t.integer  "banner_ad_override"
    t.integer  "root_parent_id"
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

  create_table "contents_locations", id: false, force: true do |t|
    t.integer "content_id"
    t.integer "location_id"
  end

  add_index "contents_locations", ["content_id", "location_id"], name: "index_contents_locations_on_content_id_and_location_id", using: :btree
  add_index "contents_locations", ["content_id"], name: "index_contents_locations_on_content_id", using: :btree
  add_index "contents_locations", ["location_id", "content_id"], name: "index_contents_locations_on_location_id_and_content_id", using: :btree
  add_index "contents_locations", ["location_id"], name: "index_contents_locations_on_location_id", using: :btree

  create_table "contents_publish_records", id: false, force: true do |t|
    t.integer "content_id"
    t.integer "publish_record_id"
  end

  create_table "contents_repositories", id: false, force: true do |t|
    t.integer "content_id",    null: false
    t.integer "repository_id", null: false
  end

  add_index "contents_repositories", ["content_id", "repository_id"], name: "index_contents_repositories_on_content_id_and_repository_id", using: :btree
  add_index "contents_repositories", ["repository_id", "content_id"], name: "index_contents_repositories_on_repository_id_and_content_id", using: :btree

  create_table "data_contexts", force: true do |t|
    t.string   "context"
    t.boolean  "loaded",     default: false
    t.datetime "last_load"
    t.boolean  "archived",   default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "datasets", force: true do |t|
    t.integer  "data_context_id"
    t.string   "name"
    t.string   "description"
    t.string   "realm"
    t.string   "model_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "event_instances", force: true do |t|
    t.integer  "event_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "subtitle_override"
    t.text     "description_override"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "presenter_name"
    t.integer  "schedule_id"
  end

  add_index "event_instances", ["end_date"], name: "index_event_instances_on_end_date", using: :btree
  add_index "event_instances", ["event_id"], name: "index_event_instances_on_event_id", using: :btree
  add_index "event_instances", ["start_date"], name: "index_event_instances_on_start_date", using: :btree

  create_table "events", force: true do |t|
    t.string   "event_type"
    t.integer  "venue_id"
    t.string   "cost"
    t.string   "event_url"
    t.string   "sponsor"
    t.string   "sponsor_url"
    t.text     "links"
    t.boolean  "featured"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "contact_phone"
    t.string   "contact_email"
    t.string   "cost_type"
    t.string   "event_category"
    t.boolean  "social_enabled",        default: false
    t.datetime "registration_deadline"
    t.string   "registration_url"
    t.string   "registration_phone"
    t.string   "registration_email"
  end

  add_index "events", ["featured"], name: "index_events_on_featured", using: :btree
  add_index "events", ["venue_id"], name: "events_on_venue_id_index", using: :btree
  add_index "events", ["venue_id"], name: "index_events_on_venue_id", using: :btree

  create_table "images", force: true do |t|
    t.string   "caption"
    t.string   "credit"
    t.string   "image"
    t.string   "imageable_type"
    t.integer  "imageable_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "source_url",     limit: 400
    t.boolean  "primary",                    default: false
  end

  add_index "images", ["imageable_type", "imageable_id"], name: "index_images_on_imageable_type_and_imageable_id", using: :btree

  create_table "import_jobs", force: true do |t|
    t.integer  "parser_id"
    t.string   "name"
    t.text     "config"
    t.string   "source_path"
    t.string   "job_type"
    t.integer  "organization_id"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "status"
    t.integer  "frequency",             default: 0
    t.boolean  "archive",               default: false, null: false
    t.integer  "content_set_id"
    t.datetime "run_at"
    t.boolean  "stop_loop",             default: true
    t.boolean  "automatically_publish", default: false
    t.integer  "repository_id"
    t.string   "publish_method"
  end

  create_table "import_locations", force: true do |t|
    t.integer  "parent_id",                  default: 0
    t.integer  "region_id",                  default: 0
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country",        limit: 128
    t.string   "link_name"
    t.string   "link_name_full"
    t.integer  "status",                     default: 0
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

  create_table "import_records", force: true do |t|
    t.integer  "import_job_id"
    t.integer  "items_imported", default: 0
    t.integer  "failures",       default: 0
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "filtered",       default: 0
  end

  create_table "issues", force: true do |t|
    t.string   "issue_edition"
    t.integer  "organization_id"
    t.string   "copyright"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "import_location_id"
    t.datetime "publication_date"
  end

  create_table "listservs", force: true do |t|
    t.string   "name"
    t.string   "reverse_publish_email"
    t.string   "import_name"
    t.boolean  "active"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "listservs_locations", id: false, force: true do |t|
    t.integer "listserv_id"
    t.integer "location_id"
  end

  create_table "locations", force: true do |t|
    t.string   "zip"
    t.string   "city"
    t.string   "state"
    t.string   "county"
    t.string   "lat"
    t.string   "long"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "consumer_active", default: false
  end

  create_table "locations_locations", id: false, force: true do |t|
    t.integer "parent_id"
    t.integer "child_id"
  end

  add_index "locations_locations", ["child_id", "parent_id"], name: "index_locations_locations_on_child_id_and_parent_id", using: :btree
  add_index "locations_locations", ["child_id"], name: "index_locations_locations_on_child_id", using: :btree
  add_index "locations_locations", ["parent_id", "child_id"], name: "index_locations_locations_on_parent_id_and_child_id", using: :btree
  add_index "locations_locations", ["parent_id"], name: "index_locations_locations_on_parent_id", using: :btree

  create_table "locations_organizations", force: true do |t|
    t.integer  "location_id"
    t.integer  "organization_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "locations_organizations", ["location_id", "organization_id"], name: "index_locations_publications_on_location_id_and_publication_id", using: :btree
  add_index "locations_organizations", ["location_id"], name: "index_locations_publications_on_location_id", using: :btree
  add_index "locations_organizations", ["organization_id", "location_id"], name: "index_locations_publications_on_publication_id_and_location_id", using: :btree
  add_index "locations_organizations", ["organization_id"], name: "index_locations_publications_on_publication_id", using: :btree

  create_table "market_posts", force: true do |t|
    t.string   "cost"
    t.string   "contact_phone"
    t.string   "contact_email"
    t.string   "contact_url"
    t.string   "locate_name"
    t.string   "locate_address"
    t.float    "latitude"
    t.float    "longitude"
    t.boolean  "locate_include_name"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "status"
    t.string   "preferred_contact_method"
  end

  create_table "messages", force: true do |t|
    t.integer  "created_by_id"
    t.string   "controller"
    t.string   "action"
    t.datetime "start_date"
    t.datetime "end_date"
    t.text     "content"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "notifiers", force: true do |t|
    t.integer  "user_id"
    t.integer  "notifyable_id"
    t.string   "notifyable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "organizations", force: true do |t|
    t.string   "name"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "logo"
    t.integer  "organization_id"
    t.string   "website"
    t.text     "notes"
    t.integer  "parent_id"
    t.string   "category_override"
    t.string   "org_type"
    t.boolean  "display_attributes",    default: false
    t.string   "reverse_publish_email"
    t.boolean  "can_reverse_publish",   default: false
    t.boolean  "can_publish_news",      default: false
  end

  add_index "organizations", ["name"], name: "index_publications_on_name", unique: true, using: :btree

  create_table "parameters", force: true do |t|
    t.integer  "parser_id"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parsers", force: true do |t|
    t.string   "filename"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "promotion_banner_reports", force: true do |t|
    t.integer  "promotion_banner_id"
    t.datetime "report_date"
    t.integer  "impression_count"
    t.integer  "click_count"
    t.integer  "total_impression_count"
    t.integer  "total_click_count"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "promotion_banners", force: true do |t|
    t.string   "banner_image"
    t.string   "redirect_url"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.date     "campaign_start"
    t.date     "campaign_end"
    t.integer  "max_impressions"
    t.integer  "impression_count",       default: 0
    t.integer  "click_count",            default: 0
    t.integer  "daily_max_impressions"
    t.boolean  "boost",                  default: false
    t.integer  "daily_impression_count", default: 0
  end

  create_table "promotion_listservs", force: true do |t|
    t.integer  "listserv_id"
    t.datetime "sent_at"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "promotions", force: true do |t|
    t.boolean  "active"
    t.string   "banner"
    t.integer  "organization_id"
    t.integer  "content_id"
    t.text     "description"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "promotable_id"
    t.string   "promotable_type"
    t.boolean  "paid",            default: false
    t.integer  "created_by"
    t.integer  "updated_by"
  end

  add_index "promotions", ["content_id"], name: "index_promotions_on_content_id", using: :btree
  add_index "promotions", ["created_by"], name: "index_promotions_on_created_by", using: :btree
  add_index "promotions", ["organization_id"], name: "index_promotions_on_publication_id", using: :btree

  create_table "publish_jobs", force: true do |t|
    t.text     "query_params"
    t.integer  "organization_id"
    t.string   "status"
    t.integer  "frequency",       default: 0
    t.string   "publish_method"
    t.boolean  "archive",         default: false
    t.string   "error"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.text     "file_archive"
    t.datetime "run_at"
  end

  create_table "publish_records", force: true do |t|
    t.integer  "publish_job_id"
    t.integer  "items_published", default: 0
    t.integer  "failures",        default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "publish_records", ["publish_job_id"], name: "index_publish_records_on_publish_job_id", using: :btree

  create_table "repositories", force: true do |t|
    t.string   "name"
    t.string   "dsp_endpoint"
    t.string   "sesame_endpoint"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "graphdb_endpoint"
    t.string   "annotate_endpoint"
    t.string   "solr_endpoint"
    t.string   "recommendation_endpoint"
  end

  create_table "rewrites", force: true do |t|
    t.string   "source"
    t.string   "destination"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "rewrites", ["created_by"], name: "index_rewrites_on_created_by", using: :btree
  add_index "rewrites", ["source"], name: "index_rewrites_on_source", unique: true, using: :btree
  add_index "rewrites", ["updated_at"], name: "index_rewrites_on_updated_at", using: :btree

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "schedules", force: true do |t|
    t.text     "recurrence"
    t.integer  "event_id"
    t.text     "description_override"
    t.string   "subtitle_override"
    t.string   "presenter_name"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "user_wufoo_forms", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "wufoo_form_id"
  end

  add_index "user_wufoo_forms", ["user_id", "wufoo_form_id"], name: "index_user_wufoo_forms_on_user_id_and_wufoo_form_id", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",         null: false
    t.string   "encrypted_password",     default: "",         null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "default_repository_id"
    t.datetime "nda_agreed_at"
    t.boolean  "agreed_to_nda",          default: false
    t.boolean  "admin",                  default: false
    t.string   "contact_phone"
    t.string   "contact_email"
    t.string   "contact_url"
    t.integer  "location_id"
    t.string   "test_group",             default: "consumer"
    t.boolean  "muted",                  default: false
    t.string   "authentication_token"
    t.string   "avatar"
    t.string   "public_id"
    t.boolean  "skip_analytics",         default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["public_id"], name: "index_users_on_public_id", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "wufoo_forms", force: true do |t|
    t.string   "form_hash"
    t.string   "email_field"
    t.string   "name"
    t.text     "call_to_action"
    t.string   "controller"
    t.string   "action"
    t.boolean  "active",         default: true
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "page_url_field"
  end

  add_index "wufoo_forms", ["controller", "action", "active"], name: "index_wufoo_forms_on_controller_and_action_and_active", unique: true, using: :btree

end
