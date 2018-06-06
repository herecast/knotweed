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

ActiveRecord::Schema.define(version: 20180531192206) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "ad_metrics", force: :cascade do |t|
    t.string   "campaign"
    t.string   "event_type"
    t.string   "page_url"
    t.string   "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "business_categories", id: :bigserial, force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.string   "icon_class",  limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "source",      limit: 255
    t.integer  "source_id",   limit: 8
  end

  add_index "business_categories", ["source", "source_id"], name: "idx_16420_index_business_categories_on_source_and_source_id", using: :btree

  create_table "business_categories_business_categories", id: false, force: :cascade do |t|
    t.integer "parent_id", limit: 8
    t.integer "child_id",  limit: 8
  end

  add_index "business_categories_business_categories", ["parent_id", "child_id"], name: "idx_16427_business_categories_index", unique: true, using: :btree

  create_table "business_categories_business_profiles", id: false, force: :cascade do |t|
    t.integer "business_category_id", limit: 8
    t.integer "business_profile_id",  limit: 8
  end

  create_table "business_feedbacks", id: :bigserial, force: :cascade do |t|
    t.integer  "created_by",          limit: 8
    t.integer  "updated_by",          limit: 8
    t.integer  "business_profile_id", limit: 8
    t.boolean  "satisfaction"
    t.boolean  "cleanliness"
    t.boolean  "price"
    t.boolean  "recommend"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "business_locations", id: :bigserial, force: :cascade do |t|
    t.string   "name",                limit: 255
    t.string   "address",             limit: 255
    t.string   "phone",               limit: 255
    t.string   "email",               limit: 255
    t.text     "hours"
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.integer  "organization_id",     limit: 8
    t.float    "latitude"
    t.float    "longitude"
    t.string   "venue_url",           limit: 255
    t.boolean  "locate_include_name",                            default: false
    t.string   "city",                limit: 255
    t.string   "state",               limit: 255
    t.string   "zip",                 limit: 255
    t.string   "status",              limit: 255
    t.integer  "created_by",          limit: 8
    t.integer  "updated_by",          limit: 8
    t.decimal  "service_radius",                  precision: 10
  end

  add_index "business_locations", ["city"], name: "idx_16441_index_business_locations_on_city", using: :btree
  add_index "business_locations", ["created_by"], name: "idx_16441_index_business_locations_on_created_by", using: :btree
  add_index "business_locations", ["name"], name: "idx_16441_index_business_locations_on_name", using: :btree

  create_table "business_profiles", id: :bigserial, force: :cascade do |t|
    t.integer  "business_location_id",      limit: 8
    t.boolean  "has_retail_location",                   default: true
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.string   "source",                    limit: 255
    t.string   "source_id",                 limit: 255
    t.float    "existence"
    t.integer  "feedback_count",            limit: 8,   default: 0
    t.float    "feedback_recommend_avg",                default: 0.0
    t.float    "feedback_price_avg",                    default: 0.0
    t.float    "feedback_satisfaction_avg",             default: 0.0
    t.float    "feedback_cleanliness_avg",              default: 0.0
    t.boolean  "archived",                              default: false
  end

  add_index "business_profiles", ["existence"], name: "idx_16451_index_business_profiles_on_existence", using: :btree
  add_index "business_profiles", ["source", "source_id"], name: "idx_16451_index_business_profiles_on_source_and_source_id", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.integer  "listserv_id"
    t.integer  "community_ids", default: [],              array: true
    t.string   "sponsored_by"
    t.text     "digest_query"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "title"
    t.string   "preheader"
    t.integer  "promotion_ids", default: [],              array: true
  end

  add_index "campaigns", ["community_ids"], name: "index_campaigns_on_community_ids", using: :btree
  add_index "campaigns", ["listserv_id"], name: "index_campaigns_on_listserv_id", using: :btree

  create_table "categories", id: :bigserial, force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "channel_id", limit: 8
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "categories", ["name"], name: "idx_16467_index_categories_on_name", using: :btree

  create_table "category_corrections", id: :bigserial, force: :cascade do |t|
    t.integer  "content_id",   limit: 8
    t.string   "old_category", limit: 255
    t.string   "new_category", limit: 255
    t.string   "user_email",   limit: 255
    t.string   "title",        limit: 255
    t.text     "content_body"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "category_corrections", ["content_id"], name: "idx_16473_index_category_corrections_on_content_id", using: :btree

  create_table "channels", id: :bigserial, force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "comments", id: :bigserial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "consumer_apps", id: :bigserial, force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "uri",        limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "consumer_apps", ["uri"], name: "idx_16494_index_consumer_apps_on_uri", unique: true, using: :btree

  create_table "consumer_apps_organizations", id: false, force: :cascade do |t|
    t.integer "consumer_app_id", limit: 8, null: false
    t.integer "organization_id", limit: 8, null: false
  end

  add_index "consumer_apps_organizations", ["consumer_app_id", "organization_id"], name: "idx_16507_consumer_app_publication_index", using: :btree

  create_table "contacts", id: :bigserial, force: :cascade do |t|
    t.string   "name",         limit: 255
    t.string   "phone",        limit: 255
    t.string   "email",        limit: 255
    t.text     "notes"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "contact_type", limit: 255
    t.text     "address"
  end

  create_table "contacts_organizations", id: false, force: :cascade do |t|
    t.integer "contact_id",      limit: 8
    t.integer "organization_id", limit: 8
  end

  create_table "content_categories", id: :bigserial, force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "parent_id",  limit: 8
    t.boolean  "active",                 default: true
  end

  create_table "content_categories_organizations", id: false, force: :cascade do |t|
    t.integer "content_category_id", limit: 8
    t.integer "organization_id",     limit: 8
  end

  add_index "content_categories_organizations", ["content_category_id", "organization_id"], name: "idx_16559_index_on_content_category_id_and_publication_id", using: :btree

  create_table "content_locations", force: :cascade do |t|
    t.integer  "content_id"
    t.integer  "location_id"
    t.string   "location_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_locations", ["content_id"], name: "index_content_locations_on_content_id", using: :btree
  add_index "content_locations", ["location_id"], name: "index_content_locations_on_location_id", using: :btree

  create_table "content_metrics", force: :cascade do |t|
    t.integer  "content_id"
    t.string   "event_type"
    t.integer  "user_id"
    t.string   "user_agent"
    t.string   "user_ip"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "client_id"
    t.integer  "location_id"
    t.integer  "organization_id"
    t.boolean  "location_confirmed", default: false
  end

  add_index "content_metrics", ["client_id"], name: "index_content_metrics_on_client_id", using: :btree
  add_index "content_metrics", ["content_id"], name: "index_content_metrics_on_content_id", using: :btree
  add_index "content_metrics", ["event_type"], name: "index_content_metrics_on_event_type", using: :btree
  add_index "content_metrics", ["location_id"], name: "index_content_metrics_on_location_id", using: :btree
  add_index "content_metrics", ["organization_id"], name: "index_content_metrics_on_organization_id", using: :btree
  add_index "content_metrics", ["user_id"], name: "index_content_metrics_on_user_id", using: :btree

  create_table "content_promotion_banner_loads", force: :cascade do |t|
    t.integer  "content_id"
    t.integer  "promotion_banner_id"
    t.integer  "load_count",          default: 1
    t.string   "select_method"
    t.float    "select_score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_reports", id: :bigserial, force: :cascade do |t|
    t.integer  "content_id",               limit: 8
    t.datetime "report_date"
    t.integer  "view_count",                         default: 0
    t.integer  "banner_click_count",                 default: 0
    t.integer  "comment_count",            limit: 8
    t.integer  "total_view_count",         limit: 8
    t.integer  "total_banner_click_count", limit: 8
    t.integer  "total_comment_count",      limit: 8
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
  end

  create_table "contents", id: :bigserial, force: :cascade do |t|
    t.string   "title",                     limit: 255
    t.string   "subtitle",                  limit: 255
    t.string   "authors",                   limit: 255
    t.text     "raw_content"
    t.integer  "issue_id",                  limit: 8
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.string   "guid",                      limit: 255
    t.datetime "pubdate"
    t.string   "source_category",           limit: 255
    t.string   "url",                       limit: 255
    t.string   "origin",                    limit: 255
    t.string   "page",                      limit: 255
    t.string   "authoremail",               limit: 255
    t.integer  "organization_id",           limit: 8
    t.boolean  "quarantine",                            default: false
    t.datetime "timestamp"
    t.integer  "parent_id",                 limit: 8
    t.integer  "content_category_id",       limit: 8
    t.boolean  "category_reviewed",                     default: false
    t.boolean  "has_event_calendar",                    default: false
    t.integer  "channelized_content_id",    limit: 8
    t.boolean  "published",                             default: false
    t.string   "channel_type",              limit: 255
    t.integer  "channel_id",                limit: 8
    t.integer  "root_content_category_id",  limit: 8
    t.integer  "view_count",                limit: 8,   default: 0
    t.integer  "comment_count",             limit: 8,   default: 0
    t.integer  "commenter_count",           limit: 8,   default: 0
    t.integer  "created_by",                limit: 8
    t.integer  "updated_by",                limit: 8
    t.integer  "banner_click_count",        limit: 8,   default: 0
    t.integer  "banner_ad_override",        limit: 8
    t.integer  "root_parent_id",            limit: 8
    t.datetime "deleted_at"
    t.boolean  "authors_is_created_by",                 default: false
    t.string   "subscriber_mc_identifier"
    t.boolean  "biz_feed_public"
    t.datetime "sunset_date"
    t.integer  "promote_radius"
    t.string   "ad_promotion_type"
    t.date     "ad_campaign_start"
    t.date     "ad_campaign_end"
    t.integer  "ad_max_impressions"
    t.string   "short_link"
    t.float    "ad_invoiced_amount"
    t.datetime "first_served_at"
    t.boolean  "removed",                               default: false
    t.string   "ugc_job"
    t.boolean  "ad_invoice_paid",                       default: false
    t.float    "ad_commission_amount"
    t.boolean  "ad_commission_paid",                    default: false
    t.float    "ad_services_amount"
    t.boolean  "ad_services_paid",                      default: false
    t.integer  "ad_sales_agent"
    t.integer  "ad_promoter"
    t.datetime "latest_activity"
    t.string   "alternate_title"
    t.integer  "alternate_organization_id"
    t.string   "alternate_authors"
    t.string   "alternate_text"
    t.string   "alternate_image_url"
    t.boolean  "has_future_event_instance"
  end

  add_index "contents", ["authoremail"], name: "idx_16527_index_contents_on_authoremail", using: :btree
  add_index "contents", ["authors"], name: "idx_16527_authors", using: :btree
  add_index "contents", ["channel_id"], name: "idx_16527_index_contents_on_channel_id", using: :btree
  add_index "contents", ["channel_type"], name: "idx_16527_index_contents_on_channel_type", using: :btree
  add_index "contents", ["channelized_content_id"], name: "idx_16527_index_contents_on_channelized_content_id", using: :btree
  add_index "contents", ["content_category_id"], name: "idx_16527_content_category_id", using: :btree
  add_index "contents", ["created_by"], name: "idx_16527_index_contents_on_created_by", using: :btree
  add_index "contents", ["guid"], name: "idx_16527_guid", using: :btree
  add_index "contents", ["organization_id"], name: "idx_16527_source_id", using: :btree
  add_index "contents", ["parent_id"], name: "idx_16527_index_contents_on_parent_id", using: :btree
  add_index "contents", ["pubdate"], name: "idx_16527_pubdate", using: :btree
  add_index "contents", ["published"], name: "idx_16527_index_contents_on_published", using: :btree
  add_index "contents", ["root_content_category_id"], name: "idx_16527_index_contents_on_root_content_category_id", using: :btree
  add_index "contents", ["root_parent_id"], name: "idx_16527_index_contents_on_root_parent_id", using: :btree
  add_index "contents", ["source_category"], name: "idx_16527_categories", using: :btree
  add_index "contents", ["title"], name: "idx_16527_title", using: :btree

  create_table "delayed_jobs", id: :bigserial, force: :cascade do |t|
    t.integer  "priority",   limit: 8,   default: 0, null: false
    t.integer  "attempts",   limit: 8,   default: 0, null: false
    t.text     "handler",                            null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "idx_16604_delayed_jobs_priority", using: :btree

  create_table "event_instances", id: :bigserial, force: :cascade do |t|
    t.integer  "event_id",             limit: 8
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "subtitle_override",    limit: 255
    t.text     "description_override"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "presenter_name",       limit: 255
    t.integer  "schedule_id",          limit: 8
  end

  add_index "event_instances", ["end_date"], name: "idx_16625_index_event_instances_on_end_date", using: :btree
  add_index "event_instances", ["event_id"], name: "idx_16625_index_event_instances_on_event_id", using: :btree
  add_index "event_instances", ["start_date"], name: "idx_16625_index_event_instances_on_start_date", using: :btree

  create_table "events", id: :bigserial, force: :cascade do |t|
    t.string   "event_type",            limit: 255
    t.integer  "venue_id",              limit: 8
    t.string   "cost",                  limit: 255
    t.string   "event_url"
    t.string   "sponsor",               limit: 255
    t.string   "sponsor_url",           limit: 255
    t.text     "links"
    t.boolean  "featured"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "contact_phone",         limit: 255
    t.string   "contact_email",         limit: 255
    t.string   "cost_type",             limit: 255
    t.string   "event_category",        limit: 255
    t.boolean  "social_enabled",                    default: false
    t.datetime "registration_deadline"
    t.string   "registration_url",      limit: 255
    t.string   "registration_phone",    limit: 255
    t.string   "registration_email",    limit: 255
  end

  add_index "events", ["featured"], name: "idx_16615_index_events_on_featured", using: :btree
  add_index "events", ["venue_id"], name: "idx_16615_events_on_venue_id_index", using: :btree
  add_index "events", ["venue_id"], name: "idx_16615_index_events_on_venue_id", using: :btree

  create_table "features", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "active"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "options"
  end

  create_table "images", id: :bigserial, force: :cascade do |t|
    t.string   "caption",        limit: 255
    t.string   "credit",         limit: 255
    t.string   "image",          limit: 255
    t.string   "imageable_type", limit: 255
    t.integer  "imageable_id",   limit: 8
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "source_url",     limit: 400
    t.boolean  "primary",                    default: false
    t.integer  "width"
    t.integer  "height"
    t.string   "file_extension"
    t.integer  "position",                   default: 0
  end

  add_index "images", ["imageable_type", "imageable_id"], name: "idx_16634_index_images_on_imageable_type_and_imageable_id", using: :btree

  create_table "issues", id: :bigserial, force: :cascade do |t|
    t.string   "issue_edition",      limit: 255
    t.integer  "organization_id",    limit: 8
    t.string   "copyright",          limit: 255
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "import_location_id", limit: 8
    t.datetime "publication_date"
  end

  create_table "listserv_digests", force: :cascade do |t|
    t.integer  "listserv_id"
    t.string   "mc_campaign_id"
    t.datetime "sent_at"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "from_name"
    t.string   "reply_to"
    t.string   "subject"
    t.string   "template"
    t.string   "sponsored_by"
    t.integer  "location_ids",     default: [],              array: true
    t.integer  "subscription_ids", default: [],              array: true
    t.string   "mc_segment_id"
    t.string   "title"
    t.string   "preheader"
    t.integer  "promotion_ids",    default: [],              array: true
    t.integer  "content_ids",                                array: true
    t.integer  "emails_sent",      default: 0,  null: false
    t.integer  "opens_total",      default: 0,  null: false
    t.hstore   "link_clicks",      default: {}, null: false
    t.datetime "last_mc_report"
  end

  add_index "listserv_digests", ["listserv_id"], name: "index_listserv_digests_on_listserv_id", using: :btree

  create_table "listservs", id: :bigserial, force: :cascade do |t|
    t.string   "name",                        limit: 255
    t.string   "reverse_publish_email",       limit: 255
    t.string   "import_name",                 limit: 255
    t.boolean  "active"
    t.datetime "created_at",                                                                     null: false
    t.datetime "updated_at",                                                                     null: false
    t.time     "digest_send_time"
    t.string   "unsubscribe_email"
    t.string   "post_email"
    t.string   "subscribe_email"
    t.string   "mc_list_id"
    t.string   "mc_group_name"
    t.boolean  "send_digest",                             default: false
    t.datetime "last_digest_send_time"
    t.datetime "last_digest_generation_time"
    t.text     "digest_header"
    t.text     "digest_footer"
    t.string   "digest_reply_to"
    t.string   "timezone",                                default: "Eastern Time (US & Canada)"
    t.text     "digest_description"
    t.string   "digest_send_day"
    t.text     "digest_query"
    t.string   "template"
    t.string   "sponsored_by"
    t.boolean  "display_subscribe",                       default: false
    t.string   "digest_subject"
    t.string   "digest_preheader"
    t.string   "list_type",                               default: "custom_list"
    t.string   "sender_name"
    t.integer  "promotion_ids",                           default: [],                                        array: true
    t.string   "admin_email"
    t.string   "forwarding_email"
    t.boolean  "forward_for_processing",                  default: false
    t.integer  "post_threshold",                          default: 0
  end

  create_table "listservs_locations", id: false, force: :cascade do |t|
    t.integer "listserv_id", limit: 8
    t.integer "location_id", limit: 8
  end

  create_table "locations", id: :bigserial, force: :cascade do |t|
    t.string   "zip",             limit: 255
    t.string   "city",            limit: 255
    t.string   "state",           limit: 255
    t.string   "county",          limit: 255
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.boolean  "consumer_active",             default: false
    t.boolean  "is_region",                   default: false
    t.string   "slug"
    t.float    "latitude"
    t.float    "longitude"
  end

  add_index "locations", ["latitude", "longitude"], name: "index_locations_on_latitude_and_longitude", using: :btree

  create_table "locations_locations", id: false, force: :cascade do |t|
    t.integer "parent_id", limit: 8
    t.integer "child_id",  limit: 8
  end

  add_index "locations_locations", ["child_id", "parent_id"], name: "idx_16707_index_locations_locations_on_child_id_and_parent_id", using: :btree
  add_index "locations_locations", ["child_id"], name: "idx_16707_index_locations_locations_on_child_id", using: :btree
  add_index "locations_locations", ["parent_id", "child_id"], name: "idx_16707_index_locations_locations_on_parent_id_and_child_id", using: :btree
  add_index "locations_locations", ["parent_id"], name: "idx_16707_index_locations_locations_on_parent_id", using: :btree

  create_table "market_posts", id: :bigserial, force: :cascade do |t|
    t.string   "cost",                     limit: 255
    t.string   "contact_phone",            limit: 255
    t.string   "contact_email",            limit: 255
    t.string   "contact_url",              limit: 255
    t.string   "locate_name",              limit: 255
    t.string   "locate_address",           limit: 255
    t.float    "latitude"
    t.float    "longitude"
    t.boolean  "locate_include_name"
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.string   "status",                   limit: 255
    t.string   "preferred_contact_method", limit: 255
    t.boolean  "sold",                                 default: false
  end

  create_table "notifiers", id: :bigserial, force: :cascade do |t|
    t.integer  "user_id",         limit: 8
    t.integer  "notifyable_id",   limit: 8
    t.string   "notifyable_type", limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "organization_content_tags", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "content_id"
  end

  add_index "organization_content_tags", ["content_id"], name: "index_organization_content_tags_on_content_id", using: :btree
  add_index "organization_content_tags", ["organization_id"], name: "index_organization_content_tags_on_organization_id", using: :btree

  create_table "organization_locations", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "location_id"
    t.string   "location_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "organization_locations", ["location_id"], name: "index_organization_locations_on_location_id", using: :btree
  add_index "organization_locations", ["organization_id"], name: "index_organization_locations_on_organization_id", using: :btree

  create_table "organizations", id: :bigserial, force: :cascade do |t|
    t.string   "name",                     limit: 255
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.string   "logo",                     limit: 255
    t.integer  "organization_id",          limit: 8
    t.string   "website",                  limit: 255
    t.text     "notes"
    t.integer  "parent_id",                limit: 8
    t.string   "org_type",                 limit: 255
    t.boolean  "can_reverse_publish",                  default: false
    t.boolean  "can_publish_news",                     default: false
    t.string   "subscribe_url",            limit: 255
    t.text     "description"
    t.string   "banner_ad_override",       limit: 255
    t.boolean  "pay_directly",                         default: false
    t.string   "profile_image",            limit: 255
    t.string   "background_image",         limit: 255
    t.string   "twitter_handle"
    t.jsonb    "custom_links"
    t.boolean  "biz_feed_active",                      default: false
    t.string   "ad_sales_agent"
    t.string   "ad_contact_nickname"
    t.string   "ad_contact_fullname"
    t.string   "profile_sales_agent"
    t.boolean  "embedded_ad",                          default: false
    t.boolean  "certified_storyteller",                default: false
    t.string   "services"
    t.boolean  "contact_card_active",                  default: true
    t.boolean  "description_card_active",              default: true
    t.boolean  "hours_card_active",                    default: true
    t.boolean  "pay_for_content",                      default: false
    t.string   "special_link_url"
    t.string   "special_link_text"
    t.boolean  "certified_social",                     default: false
    t.string   "desktop_image"
    t.boolean  "archived",                             default: false
    t.boolean  "feature_notification_org",             default: false
    t.boolean  "standard_ugc_org",                     default: false
    t.boolean  "calendar_view_first",                  default: false
    t.boolean  "calendar_card_active",                 default: false
  end

  add_index "organizations", ["name"], name: "idx_16739_index_publications_on_name", unique: true, using: :btree

  create_table "profile_metrics", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "location_id"
    t.integer  "user_id"
    t.integer  "content_id"
    t.string   "event_type"
    t.string   "user_ip"
    t.string   "user_agent"
    t.string   "client_id"
    t.boolean  "location_confirmed"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "profile_metrics", ["client_id"], name: "index_profile_metrics_on_client_id", using: :btree
  add_index "profile_metrics", ["content_id"], name: "index_profile_metrics_on_content_id", using: :btree
  add_index "profile_metrics", ["event_type"], name: "index_profile_metrics_on_event_type", using: :btree
  add_index "profile_metrics", ["location_id"], name: "index_profile_metrics_on_location_id", using: :btree
  add_index "profile_metrics", ["organization_id"], name: "index_profile_metrics_on_organization_id", using: :btree
  add_index "profile_metrics", ["user_id"], name: "index_profile_metrics_on_user_id", using: :btree

  create_table "promotion_banner_metrics", force: :cascade do |t|
    t.integer  "promotion_banner_id"
    t.string   "event_type"
    t.integer  "content_id"
    t.string   "select_method"
    t.float    "select_score"
    t.integer  "user_id"
    t.string   "location"
    t.string   "page_url"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "gtm_blocked"
    t.string   "user_agent"
    t.string   "user_ip"
    t.string   "page_placement"
    t.string   "client_id"
    t.integer  "location_id"
    t.float    "load_time"
    t.boolean  "location_confirmed",  default: false
  end

  add_index "promotion_banner_metrics", ["content_id"], name: "index_promotion_banner_metrics_on_content_id", using: :btree
  add_index "promotion_banner_metrics", ["created_at"], name: "index_promotion_banner_metrics_on_created_at", using: :btree
  add_index "promotion_banner_metrics", ["event_type"], name: "index_promotion_banner_metrics_on_event_type", using: :btree
  add_index "promotion_banner_metrics", ["promotion_banner_id"], name: "index_promotion_banner_metrics_on_promotion_banner_id", using: :btree

  create_table "promotion_banner_reports", id: :bigserial, force: :cascade do |t|
    t.integer  "promotion_banner_id",    limit: 8
    t.datetime "report_date"
    t.integer  "impression_count",       limit: 8
    t.integer  "click_count",            limit: 8
    t.integer  "total_impression_count", limit: 8
    t.integer  "total_click_count",      limit: 8
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "load_count"
  end

  add_index "promotion_banner_reports", ["promotion_banner_id"], name: "index_promotion_banner_reports_on_promotion_banner_id", using: :btree
  add_index "promotion_banner_reports", ["report_date"], name: "index_promotion_banner_reports_on_report_date", using: :btree

  create_table "promotion_banners", id: :bigserial, force: :cascade do |t|
    t.string   "banner_image",           limit: 255
    t.string   "redirect_url",           limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.date     "campaign_start"
    t.date     "campaign_end"
    t.integer  "max_impressions",        limit: 8
    t.integer  "impression_count",       limit: 8,   default: 0
    t.integer  "click_count",            limit: 8,   default: 0
    t.integer  "daily_max_impressions",  limit: 8
    t.boolean  "boost",                              default: false
    t.integer  "daily_impression_count", limit: 8,   default: 0
    t.integer  "load_count",                         default: 0
    t.integer  "integer",                            default: 0
    t.string   "promotion_type"
    t.float    "cost_per_impression"
    t.float    "cost_per_day"
    t.text     "coupon_email_body"
    t.string   "coupon_image"
    t.string   "sales_agent"
    t.integer  "digest_clicks",                      default: 0,     null: false
    t.integer  "digest_opens",                       default: 0,     null: false
    t.integer  "digest_emails",                      default: 0,     null: false
    t.datetime "digest_metrics_updated"
  end

  create_table "promotion_listservs", id: :bigserial, force: :cascade do |t|
    t.integer  "listserv_id", limit: 8
    t.datetime "sent_at"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "promotions", id: :bigserial, force: :cascade do |t|
    t.string   "banner",          limit: 255
    t.integer  "content_id",      limit: 8
    t.text     "description"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "promotable_id",   limit: 8
    t.string   "promotable_type", limit: 255
    t.boolean  "paid",                        default: false
    t.integer  "created_by",      limit: 8
    t.integer  "updated_by",      limit: 8
    t.string   "share_platform"
  end

  add_index "promotions", ["content_id"], name: "idx_16765_index_promotions_on_content_id", using: :btree
  add_index "promotions", ["created_by"], name: "idx_16765_index_promotions_on_created_by", using: :btree

  create_table "report_job_params", force: :cascade do |t|
    t.string   "report_job_paramable_type"
    t.integer  "report_job_paramable_id"
    t.string   "param_name"
    t.string   "param_value"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "report_job_params", ["report_job_paramable_type", "report_job_paramable_id"], name: "report_job_params_paramable_type_id", using: :btree

  create_table "report_job_recipients", force: :cascade do |t|
    t.integer  "report_job_id"
    t.integer  "report_recipient_id"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.datetime "report_review_date"
    t.datetime "report_sent_date"
    t.text     "jasper_review_response"
    t.boolean  "run_failed",             default: false
    t.text     "jasper_sent_response"
  end

  create_table "report_jobs", force: :cascade do |t|
    t.integer  "report_id"
    t.text     "description"
    t.datetime "report_review_date"
    t.datetime "report_sent_date"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "report_params", force: :cascade do |t|
    t.integer  "report_id"
    t.string   "report_param_type"
    t.string   "param_name"
    t.string   "param_value"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "report_recipients", force: :cascade do |t|
    t.integer  "report_id"
    t.integer  "user_id"
    t.string   "alternative_emails"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "archived",           default: false
  end

  add_index "report_recipients", ["user_id", "report_id"], name: "index_report_recipients_on_user_id_and_report_id", using: :btree

  create_table "reports", force: :cascade do |t|
    t.string   "title"
    t.string   "report_path"
    t.string   "output_formats_review"
    t.string   "output_formats_send"
    t.string   "output_file_name"
    t.string   "repository_folder"
    t.boolean  "overwrite_files",       default: false
    t.text     "notes"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "email_subject"
    t.string   "alert_recipients"
    t.string   "cc_emails"
    t.string   "bcc_emails"
  end

  create_table "repositories", id: :bigserial, force: :cascade do |t|
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

  create_table "rewrites", id: :bigserial, force: :cascade do |t|
    t.string   "source",      limit: 255
    t.string   "destination", limit: 255
    t.integer  "created_by",  limit: 8
    t.integer  "updated_by",  limit: 8
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "rewrites", ["created_by"], name: "idx_16828_index_rewrites_on_created_by", using: :btree
  add_index "rewrites", ["source"], name: "idx_16828_index_rewrites_on_source", unique: true, using: :btree
  add_index "rewrites", ["updated_at"], name: "idx_16828_index_rewrites_on_updated_at", using: :btree

  create_table "roles", id: :bigserial, force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "resource_id",   limit: 8
    t.string   "resource_type", limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "idx_16837_index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "idx_16837_index_roles_on_name", using: :btree

  create_table "schedules", id: :bigserial, force: :cascade do |t|
    t.text     "recurrence"
    t.integer  "event_id",             limit: 8
    t.text     "description_override"
    t.string   "subtitle_override",    limit: 255
    t.string   "presenter_name",       limit: 255
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  create_table "sign_in_tokens", force: :cascade do |t|
    t.string   "token",      null: false
    t.integer  "user_id"
    t.datetime "created_at", null: false
  end

  add_index "sign_in_tokens", ["token"], name: "index_sign_in_tokens_on_token", using: :btree
  add_index "sign_in_tokens", ["user_id"], name: "index_sign_in_tokens_on_user_id", using: :btree

  create_table "social_logins", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.string   "provider",   null: false
    t.string   "uid",        null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json     "extra_info"
  end

  add_index "social_logins", ["user_id"], name: "index_social_logins_on_user_id", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "listserv_id"
    t.datetime "confirmed_at"
    t.datetime "unsubscribed_at"
    t.boolean  "blacklist",            default: false
    t.string   "subscription_details"
    t.string   "source"
    t.string   "email",                                 null: false
    t.string   "confirmation_details"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "key",                                   null: false
    t.string   "name"
    t.string   "confirm_ip"
    t.string   "email_type",           default: "html"
    t.datetime "mc_unsubscribed_at"
  end

  add_index "subscriptions", ["listserv_id"], name: "index_subscriptions_on_listserv_id", using: :btree
  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "user_bookmarks", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "content_id"
    t.integer  "event_instance_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.boolean  "read",              default: false
    t.datetime "deleted_at"
  end

  add_index "user_bookmarks", ["content_id"], name: "index_user_bookmarks_on_content_id", using: :btree
  add_index "user_bookmarks", ["deleted_at"], name: "index_user_bookmarks_on_deleted_at", using: :btree
  add_index "user_bookmarks", ["user_id"], name: "index_user_bookmarks_on_user_id", using: :btree

  create_table "users", id: :bigserial, force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",         null: false
    t.string   "encrypted_password",     limit: 255, default: "",         null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 8,   default: 0
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
    t.integer  "default_repository_id",  limit: 8
    t.datetime "nda_agreed_at"
    t.boolean  "agreed_to_nda",                      default: false
    t.string   "contact_phone",          limit: 255
    t.string   "contact_email",          limit: 255
    t.string   "contact_url",            limit: 255
    t.integer  "location_id",            limit: 8
    t.string   "test_group",             limit: 255, default: "consumer"
    t.boolean  "muted",                              default: false
    t.string   "authentication_token",   limit: 255
    t.string   "avatar",                 limit: 255
    t.string   "public_id",              limit: 255
    t.boolean  "skip_analytics",                     default: false
    t.string   "temp_password"
    t.boolean  "archived",                           default: false
    t.string   "source"
    t.boolean  "receive_comment_alerts",             default: true
    t.boolean  "location_confirmed",                 default: false
    t.string   "fullname"
    t.string   "nickname"
    t.boolean  "epayment",                           default: false
    t.boolean  "w9",                                 default: false
    t.boolean  "has_had_bookmarks",                  default: false
  end

  add_index "users", ["email"], name: "idx_16858_index_users_on_email", unique: true, using: :btree
  add_index "users", ["public_id"], name: "idx_16858_index_users_on_public_id", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "idx_16858_index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id", limit: 8
    t.integer "role_id", limit: 8
  end

  add_index "users_roles", ["user_id", "role_id"], name: "idx_16873_index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "x_content_campaigns", id: false, force: :cascade do |t|
    t.integer  "id",                        limit: 8
    t.string   "title",                     limit: 255
    t.string   "subtitle",                  limit: 255
    t.string   "authors",                   limit: 255
    t.text     "raw_content"
    t.integer  "issue_id",                  limit: 8
    t.integer  "import_location_id",        limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.integer  "organization_id",           limit: 8
    t.boolean  "quarantine"
    t.string   "doctype",                   limit: 255
    t.datetime "timestamp"
    t.string   "contentsource",             limit: 255
    t.integer  "import_record_id",          limit: 8
    t.string   "source_content_id",         limit: 255
    t.integer  "parent_id",                 limit: 8
    t.integer  "content_category_id",       limit: 8
    t.boolean  "category_reviewed"
    t.boolean  "has_event_calendar"
    t.integer  "channelized_content_id",    limit: 8
    t.boolean  "published"
    t.string   "channel_type",              limit: 255
    t.integer  "channel_id",                limit: 8
    t.integer  "root_content_category_id",  limit: 8
    t.integer  "view_count",                limit: 8
    t.integer  "comment_count",             limit: 8
    t.integer  "commenter_count",           limit: 8
    t.integer  "created_by",                limit: 8
    t.integer  "updated_by",                limit: 8
    t.integer  "banner_click_count",        limit: 8
    t.text     "similar_content_overrides"
    t.integer  "banner_ad_override",        limit: 8
    t.integer  "root_parent_id",            limit: 8
    t.datetime "deleted_at"
    t.boolean  "authors_is_created_by"
    t.string   "subscriber_mc_identifier"
    t.boolean  "biz_feed_public"
    t.datetime "sunset_date"
    t.integer  "promote_radius"
    t.string   "ad_promotion_type"
    t.date     "ad_campaign_start"
    t.date     "ad_campaign_end"
    t.integer  "ad_max_impressions"
    t.string   "short_link"
    t.float    "ad_invoiced_amount"
    t.datetime "first_served_at"
  end

  add_foreign_key "campaigns", "listservs"
  add_foreign_key "content_locations", "contents"
  add_foreign_key "content_locations", "locations"
  add_foreign_key "listserv_digests", "listservs"
  add_foreign_key "organization_content_tags", "contents"
  add_foreign_key "organization_content_tags", "organizations"
  add_foreign_key "organization_locations", "locations"
  add_foreign_key "organization_locations", "organizations"
  add_foreign_key "profile_metrics", "contents"
  add_foreign_key "profile_metrics", "locations"
  add_foreign_key "profile_metrics", "organizations"
  add_foreign_key "profile_metrics", "users"
  add_foreign_key "sign_in_tokens", "users"
  add_foreign_key "social_logins", "users"
  add_foreign_key "subscriptions", "listservs"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "user_bookmarks", "contents"
  add_foreign_key "user_bookmarks", "users"
end
