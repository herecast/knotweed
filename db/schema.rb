# frozen_string_literal: true

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

ActiveRecord::Schema.define(version: 20191022172142) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_stat_statements'
  enable_extension 'plpgsql'
  enable_extension 'fuzzystrmatch'
  enable_extension 'hstore'

  create_table 'business_locations', id: :bigserial, force: :cascade do |t|
    t.string   'name',                limit: 255
    t.string   'address',             limit: 255
    t.string   'phone',               limit: 255
    t.string   'email',               limit: 255
    t.text     'hours'
    t.datetime 'created_at',                                                     null: false
    t.datetime 'updated_at',                                                     null: false
    t.bigint   'organization_id'
    t.float    'latitude'
    t.float    'longitude'
    t.string   'venue_url', limit: 255
    t.boolean  'locate_include_name', default: false
    t.string   'city',                limit: 255
    t.string   'state',               limit: 255
    t.string   'zip',                 limit: 255
    t.string   'status',              limit: 255
    t.bigint   'created_by_id'
    t.bigint   'updated_by_id'
    t.decimal  'service_radius', precision: 10
    t.index ['city'], name: 'idx_16441_index_business_locations_on_city', using: :btree
    t.index ['created_by_id'], name: 'idx_16441_index_business_locations_on_created_by_id', using: :btree
    t.index ['name'], name: 'idx_16441_index_business_locations_on_name', using: :btree
  end

  create_table 'campaigns', force: :cascade do |t|
    t.integer  'listserv_id'
    t.integer  'community_ids', default: [], array: true
    t.string   'sponsored_by'
    t.datetime 'created_at',                 null: false
    t.datetime 'updated_at',                 null: false
    t.string   'title'
    t.string   'preheader'
    t.integer  'promotion_ids', default: [], array: true
    t.index ['community_ids'], name: 'index_campaigns_on_community_ids', using: :btree
    t.index ['listserv_id'], name: 'index_campaigns_on_listserv_id', using: :btree
  end

  create_table 'channels', id: :bigserial, force: :cascade do |t|
    t.string   'name', limit: 255
    t.datetime 'created_at',             null: false
    t.datetime 'updated_at',             null: false
  end

  create_table 'comments', id: :bigserial, force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'content_metrics', force: :cascade do |t|
    t.integer  'content_id'
    t.string   'event_type'
    t.integer  'user_id'
    t.string   'user_agent'
    t.string   'user_ip'
    t.datetime 'created_at',                         null: false
    t.datetime 'updated_at',                         null: false
    t.string   'client_id'
    t.integer  'location_id'
    t.integer  'organization_id'
    t.boolean  'location_confirmed', default: false
    t.index ['client_id'], name: 'index_content_metrics_on_client_id', using: :btree
    t.index ['content_id'], name: 'index_content_metrics_on_content_id', using: :btree
    t.index ['event_type'], name: 'index_content_metrics_on_event_type', using: :btree
    t.index ['location_id'], name: 'index_content_metrics_on_location_id', using: :btree
    t.index ['organization_id'], name: 'index_content_metrics_on_organization_id', using: :btree
    t.index ['user_id'], name: 'index_content_metrics_on_user_id', using: :btree
    t.index ['created_at'], name: 'index_content_metrics_on_created_at', using: :btree
  end

  create_table 'content_reports', id: :bigserial, force: :cascade do |t|
    t.bigint   'content_id'
    t.datetime 'report_date'
    t.integer  'view_count',               default: 0
    t.integer  'banner_click_count',       default: 0
    t.bigint   'comment_count'
    t.bigint   'total_view_count'
    t.bigint   'total_banner_click_count'
    t.bigint   'total_comment_count'
    t.datetime 'created_at',                           null: false
    t.datetime 'updated_at',                           null: false
  end

  create_table 'contents', id: :bigserial, force: :cascade do |t|
    t.string   'title',                     limit: 255
    t.string   'subtitle',                  limit: 255
    t.string   'authors',                   limit: 255
    t.text     'raw_content'
    t.datetime 'created_at',                                            null: false
    t.datetime 'updated_at',                                            null: false
    t.datetime 'pubdate'
    t.string   'url',                       limit: 255
    t.string   'origin',                    limit: 255
    t.string   'page',                      limit: 255
    t.string   'authoremail',               limit: 255
    t.bigint   'organization_id'
    t.datetime 'timestamp'
    t.bigint   'parent_id'
    t.boolean  'has_event_calendar', default: false
    t.bigint   'channelized_content_id'
    t.string   'channel_type', limit: 255
    t.bigint   'channel_id'
    t.bigint   'view_count',                            default: 0
    t.bigint   'comment_count',                         default: 0
    t.bigint   'commenter_count',                       default: 0
    t.bigint   'created_by_id'
    t.bigint   'updated_by_id'
    t.bigint   'banner_click_count', default: 0
    t.text     'similar_content_overrides'
    t.bigint   'banner_ad_override'
    t.bigint   'root_parent_id'
    t.datetime 'deleted_at'
    t.boolean  'authors_is_created_by', default: false
    t.string   'subscriber_mc_identifier'
    t.boolean  'biz_feed_public'
    t.datetime 'sunset_date'
    t.integer  'promote_radius'
    t.string   'ad_promotion_type'
    t.date     'ad_campaign_start'
    t.date     'ad_campaign_end'
    t.integer  'ad_max_impressions'
    t.string   'short_link'
    t.float    'ad_invoiced_amount'
    t.datetime 'first_served_at'
    t.boolean  'removed',                               default: false
    t.boolean  'ad_invoice_paid',                       default: false
    t.float    'ad_commission_amount'
    t.boolean  'ad_commission_paid', default: false
    t.float    'ad_services_amount'
    t.boolean  'ad_services_paid', default: false
    t.integer  'ad_sales_agent'
    t.integer  'ad_promoter'
    t.datetime 'latest_activity'
    t.boolean  'has_future_event_instance'
    t.string   'alternate_title'
    t.integer  'alternate_organization_id'
    t.string   'alternate_authors'
    t.string   'alternate_text'
    t.string   'alternate_image_url'
    t.boolean  'has_future_event_instance'
    t.integer  'location_id'
    t.string   'mc_campaign_id'
    t.string "ad_service_id"
    t.string "content_category"
    t.index ["content_category"], name: "index_contents_on_content_category"
    t.index ["ad_service_id"], name: "index_contents_on_ad_service_id"
    t.index ['authoremail'], name: 'idx_16527_index_contents_on_authoremail', using: :btree
    t.index ['authors'], name: 'idx_16527_authors', using: :btree
    t.index ['channel_id'], name: 'idx_16527_index_contents_on_channel_id', using: :btree
    t.index ['channel_type'], name: 'idx_16527_index_contents_on_channel_type', using: :btree
    t.index ['channelized_content_id'], name: 'idx_16527_index_contents_on_channelized_content_id', using: :btree
    t.index ['created_by_id'], name: 'idx_16527_index_contents_on_created_by_id', using: :btree
    t.index ['organization_id'], name: 'idx_16527_source_id', using: :btree
    t.index ['parent_id'], name: 'idx_16527_index_contents_on_parent_id', using: :btree
    t.index ['pubdate'], name: 'idx_16527_pubdate', using: :btree
    t.index ['root_parent_id'], name: 'idx_16527_index_contents_on_root_parent_id', using: :btree
    t.index ['title'], name: 'idx_16527_title', using: :btree
  end

  create_table 'event_instances', id: :bigserial, force: :cascade do |t|
    t.bigint   'event_id'
    t.datetime 'start_date'
    t.datetime 'end_date'
    t.string   'subtitle_override', limit: 255
    t.text     'description_override'
    t.datetime 'created_at',                       null: false
    t.datetime 'updated_at',                       null: false
    t.string   'presenter_name', limit: 255
    t.bigint   'schedule_id'
    t.index ['end_date'], name: 'idx_16625_index_event_instances_on_end_date', using: :btree
    t.index ['event_id'], name: 'idx_16625_index_event_instances_on_event_id', using: :btree
    t.index ['start_date'], name: 'idx_16625_index_event_instances_on_start_date', using: :btree
  end

  create_table 'events', id: :bigserial, force: :cascade do |t|
    t.string   'event_type', limit: 255
    t.bigint   'venue_id'
    t.string   'cost', limit: 255
    t.string   'event_url'
    t.string   'sponsor',               limit: 255
    t.string   'sponsor_url',           limit: 255
    t.text     'links'
    t.boolean  'featured'
    t.datetime 'created_at',                                        null: false
    t.datetime 'updated_at',                                        null: false
    t.string   'contact_phone',         limit: 255
    t.string   'contact_email',         limit: 255
    t.string   'cost_type',             limit: 255
    t.string   'event_category',        limit: 255
    t.boolean  'social_enabled', default: false
    t.datetime 'registration_deadline'
    t.string   'registration_url',      limit: 255
    t.string   'registration_phone',    limit: 255
    t.string   'registration_email',    limit: 255
    t.index ['featured'], name: 'idx_16615_index_events_on_featured', using: :btree
    t.index ['venue_id'], name: 'idx_16615_events_on_venue_id_index', using: :btree
    t.index ['venue_id'], name: 'idx_16615_index_events_on_venue_id', using: :btree
  end

  create_table 'external_advertiser_reports', force: :cascade do |t|
    t.string   'title'
    t.string   'pdf'
    t.bigint   'organization_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['organization_id'], name: 'index_external_advertiser_reports_on_organization_id', using: :btree
  end

  create_table 'features', force: :cascade do |t|
    t.string   'name'
    t.text     'description'
    t.boolean  'active'
    t.datetime 'created_at',  null: false
    t.datetime 'updated_at',  null: false
    t.text     'options'
  end

  create_table 'images', id: :bigserial, force: :cascade do |t|
    t.string   'caption',        limit: 255
    t.string   'credit',         limit: 255
    t.string   'image',          limit: 255
    t.string   'imageable_type', limit: 255
    t.bigint   'imageable_id'
    t.datetime 'created_at',                                 null: false
    t.datetime 'updated_at',                                 null: false
    t.string   'source_url', limit: 400
    t.boolean  'primary', default: false
    t.integer  'width'
    t.integer  'height'
    t.string   'file_extension'
    t.integer  'position', default: 0
    t.index %w[imageable_type imageable_id], name: 'idx_16634_index_images_on_imageable_type_and_imageable_id', using: :btree
  end

  create_table 'listserv_digests', force: :cascade do |t|
    t.integer  'listserv_id'
    t.string   'mc_campaign_id'
    t.datetime 'sent_at'
    t.datetime 'created_at',                    null: false
    t.datetime 'updated_at',                    null: false
    t.string   'from_name'
    t.string   'reply_to'
    t.string   'subject'
    t.string   'template'
    t.string   'sponsored_by'
    t.integer  'location_ids',     default: [],              array: true
    t.integer  'subscription_ids', default: [],              array: true
    t.string   'mc_segment_id'
    t.string   'title'
    t.string   'preheader'
    t.integer  'promotion_ids', default: [], array: true
    t.integer  'content_ids', array: true
    t.integer  'emails_sent',      default: 0,  null: false
    t.integer  'opens_total',      default: 0,  null: false
    t.hstore   'link_clicks',      default: {}, null: false
    t.datetime 'last_mc_report'
    t.bigint   'location_id'
    t.index ['listserv_id'], name: 'index_listserv_digests_on_listserv_id', using: :btree
    t.index ["location_id"], name: "index_listserv_digests_on_location_id", using: :btree
  end

  create_table 'listservs', id: :bigserial, force: :cascade do |t|
    t.string   'name',                        limit: 255
    t.string   'import_name',                 limit: 255
    t.boolean  'active'
    t.datetime 'created_at',                                                                     null: false
    t.datetime 'updated_at',                                                                     null: false
    t.time     'digest_send_time'
    t.string   'unsubscribe_email'
    t.string   'post_email'
    t.string   'subscribe_email'
    t.string   'mc_list_id'
    t.string   'mc_group_name'
    t.boolean  'send_digest', default: false
    t.datetime 'last_digest_send_time'
    t.datetime 'last_digest_generation_time'
    t.text     'digest_header'
    t.text     'digest_footer'
    t.string   'digest_reply_to'
    t.string   'timezone', default: 'Eastern Time (US & Canada)'
    t.text     'digest_description'
    t.string   'digest_send_day'
    t.string   'template'
    t.string   'sponsored_by'
    t.boolean  'display_subscribe', default: false
    t.string   'digest_subject'
    t.string   'digest_preheader'
    t.string   'sender_name'
    t.integer  'promotion_ids', default: [], array: true
    t.string   'admin_email'
    t.string   'forwarding_email'
    t.boolean  'forward_for_processing',                  default: false
    t.integer  'post_threshold',                          default: 0
  end

  create_table 'listservs_locations', id: false, force: :cascade do |t|
    t.bigint 'listserv_id'
    t.bigint 'location_id'
  end

  create_table 'locations', id: :bigserial, force: :cascade do |t|
    t.string   'zip',                             limit: 255
    t.string   'city',                            limit: 255
    t.string   'state',                           limit: 255
    t.string   'county',                          limit: 255
    t.datetime 'created_at',                                                  null: false
    t.datetime 'updated_at',                                                  null: false
    t.boolean  'consumer_active',                             default: false
    t.boolean  'is_region',                                   default: false
    t.string   'slug'
    t.float    'latitude'
    t.float    'longitude'
    t.boolean  'default_location',                            default: false
    t.integer  'location_ids_within_five_miles',              default: [],                 array: true
    t.integer  'location_ids_within_fifty_miles',             default: [],                 array: true
    t.string   'image'
    t.index %w[latitude longitude], name: 'index_locations_on_latitude_and_longitude', using: :btree
  end

  create_table 'locations_locations', id: false, force: :cascade do |t|
    t.bigint 'parent_id'
    t.bigint 'child_id'
    t.index %w[child_id parent_id], name: 'idx_16707_index_locations_locations_on_child_id_and_parent_id', using: :btree
    t.index ['child_id'], name: 'idx_16707_index_locations_locations_on_child_id', using: :btree
    t.index %w[parent_id child_id], name: 'idx_16707_index_locations_locations_on_parent_id_and_child_id', using: :btree
    t.index ['parent_id'], name: 'idx_16707_index_locations_locations_on_parent_id', using: :btree
  end

  create_table 'market_posts', id: :bigserial, force: :cascade do |t|
    t.string   'cost',                     limit: 255
    t.string   'contact_phone',            limit: 255
    t.string   'contact_email',            limit: 255
    t.string   'contact_url',              limit: 255
    t.string   'locate_name',              limit: 255
    t.string   'locate_address',           limit: 255
    t.float    'latitude'
    t.float    'longitude'
    t.boolean  'locate_include_name'
    t.datetime 'created_at',                                           null: false
    t.datetime 'updated_at',                                           null: false
    t.string   'status',                   limit: 255
    t.string   'preferred_contact_method', limit: 255
    t.boolean  'sold', default: false
  end

  create_table 'organization_content_tags', force: :cascade do |t|
    t.integer  'organization_id'
    t.integer  'content_id'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.index ['content_id'], name: 'index_organization_content_tags_on_content_id', using: :btree
    t.index ['organization_id'], name: 'index_organization_content_tags_on_organization_id', using: :btree
  end

  create_table 'organization_hides', force: :cascade do |t|
    t.bigint   'user_id'
    t.datetime 'deleted_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string   'flag_type'
    t.bigint   'content_id'
    t.integer  'caster_id'
    t.index ['caster_id'], name: 'index_organization_hides_on_caster_id'
    t.index ['content_id'], name: 'index_organization_hides_on_content_id'
    t.index ['user_id'], name: 'index_organization_hides_on_user_id'
  end

  create_table 'organization_locations', force: :cascade do |t|
    t.integer  'organization_id'
    t.integer  'location_id'
    t.string   'location_type'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.index ['location_id'], name: 'index_organization_locations_on_location_id', using: :btree
    t.index ['organization_id'], name: 'index_organization_locations_on_organization_id', using: :btree
  end

  create_table 'organization_subscriptions', force: :cascade do |t|
    t.bigint   'user_id'
    t.bigint   'organization_id'
    t.string   'mc_subscriber_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.datetime 'deleted_at'
    t.integer  'caster_id'
    t.index ['caster_id'], name: 'index_organization_subscriptions_on_caster_id'
    t.index ['organization_id'], name: 'index_organization_subscriptions_on_organization_id'
    t.index %w[user_id organization_id], name: 'index_organization_subscriptions_on_user_id_and_organization_id', unique: true
    t.index ['user_id'], name: 'index_organization_subscriptions_on_user_id'
  end

  create_table 'organizations', id: :bigserial, force: :cascade do |t|
    t.string   'name', limit: 255
    t.datetime 'created_at',                                           null: false
    t.datetime 'updated_at',                                           null: false
    t.string   'logo', limit: 255
    t.bigint   'organization_id'
    t.string   'website', limit: 255
    t.text     'notes'
    t.bigint   'parent_id'
    t.string   'org_type', limit: 255
    t.boolean  'can_reverse_publish',                  default: false
    t.boolean  'can_publish_news',                     default: false
    t.text     'description'
    t.string   'banner_ad_override', limit: 255
    t.boolean  'pay_directly', default: false
    t.string   'profile_image',            limit: 255
    t.string   'background_image',         limit: 255
    t.string   'twitter_handle'
    t.jsonb    'custom_links'
    t.boolean  'biz_feed_active', default: false
    t.string   'ad_sales_agent'
    t.string   'ad_contact_nickname'
    t.string   'ad_contact_fullname'
    t.string   'profile_sales_agent'
    t.boolean  'certified_storyteller', default: false
    t.string   'services'
    t.boolean  'contact_card_active',                  default: true
    t.boolean  'description_card_active',              default: true
    t.boolean  'hours_card_active',                    default: true
    t.boolean  'pay_for_content',                      default: false
    t.string   'special_link_url'
    t.string   'special_link_text'
    t.boolean  'certified_social', default: false
    t.string   'desktop_image'
    t.boolean  'archived',                             default: false
    t.boolean  'feature_notification_org',             default: false
    t.boolean  'standard_ugc_org',                     default: false
    t.boolean  'calendar_view_first',                  default: false
    t.boolean  'calendar_card_active',                 default: false
    t.boolean  'embedded_ad',                          default: true
    t.integer  'digest_id'
    t.string   'reminder_campaign_id'
    t.string   'mc_segment_id'
    t.string   'ad_contact_email'
    t.bigint   'user_id'
    t.string "ad_service_id"
    t.index ["ad_service_id"], name: "index_organizations_on_ad_service_id"
    t.index ['name'], name: 'idx_16739_index_publications_on_name', unique: true, using: :btree
    t.index ['user_id'], name: 'index_organizations_on_user_id', using: :btree
  end

  create_table 'payment_recipients', force: :cascade do |t|
    t.integer  'user_id'
    t.integer  'organization_id'
    t.datetime 'created_at',      null: false
    t.datetime 'updated_at',      null: false
    t.index ['organization_id'], name: 'index_payment_recipients_on_organization_id', using: :btree
    t.index ['user_id'], name: 'index_payment_recipients_on_user_id', using: :btree
  end

  create_table 'payments', force: :cascade do |t|
    t.date     'period_start'
    t.date     'period_end'
    t.integer  'paid_impressions'
    t.decimal  'pay_per_impression'
    t.decimal  'total_payment'
    t.date     'payment_date'
    t.datetime 'created_at',                         null: false
    t.datetime 'updated_at',                         null: false
    t.integer  'content_id'
    t.integer  'paid_to_id'
    t.decimal 'period_ad_rev'
    t.boolean 'paid', default: false
    t.index ['paid_to_id'], name: 'index_payments_on_paid_to_id', using: :btree
  end

  create_table 'profile_metrics', force: :cascade do |t|
    t.integer  'organization_id'
    t.integer  'location_id'
    t.integer  'user_id'
    t.integer  'content_id'
    t.string   'event_type'
    t.string   'user_ip'
    t.string   'user_agent'
    t.string   'client_id'
    t.boolean  'location_confirmed'
    t.datetime 'created_at',         null: false
    t.datetime 'updated_at',         null: false
    t.index ['client_id'], name: 'index_profile_metrics_on_client_id', using: :btree
    t.index ['content_id'], name: 'index_profile_metrics_on_content_id', using: :btree
    t.index ['event_type'], name: 'index_profile_metrics_on_event_type', using: :btree
    t.index ['location_id'], name: 'index_profile_metrics_on_location_id', using: :btree
    t.index ['organization_id'], name: 'index_profile_metrics_on_organization_id', using: :btree
    t.index ['user_id'], name: 'index_profile_metrics_on_user_id', using: :btree
  end

  create_table 'promotion_banner_metrics', force: :cascade do |t|
    t.integer  'promotion_banner_id'
    t.string   'event_type'
    t.integer  'content_id'
    t.string   'select_method'
    t.float    'select_score'
    t.integer  'user_id'
    t.string   'location'
    t.string   'page_url'
    t.datetime 'created_at',                          null: false
    t.datetime 'updated_at',                          null: false
    t.boolean  'gtm_blocked'
    t.string   'user_agent'
    t.string   'user_ip'
    t.string   'page_placement'
    t.string   'client_id'
    t.integer  'location_id'
    t.float    'load_time'
    t.boolean  'location_confirmed', default: false
    t.index ['content_id'], name: 'index_promotion_banner_metrics_on_content_id', using: :btree
    t.index ['created_at'], name: 'index_promotion_banner_metrics_on_created_at', using: :btree
    t.index ['event_type'], name: 'index_promotion_banner_metrics_on_event_type', using: :btree
    t.index ['promotion_banner_id'], name: 'index_promotion_banner_metrics_on_promotion_banner_id', using: :btree
  end

  create_table 'promotion_banners', id: :bigserial, force: :cascade do |t|
    t.string   'banner_image',           limit: 255
    t.string   'redirect_url',           limit: 255
    t.datetime 'created_at',                                         null: false
    t.datetime 'updated_at',                                         null: false
    t.date     'campaign_start'
    t.date     'campaign_end'
    t.bigint   'max_impressions'
    t.bigint   'impression_count',                   default: 0
    t.bigint   'click_count',                        default: 0
    t.bigint   'daily_max_impressions'
    t.boolean  'boost',                              default: false
    t.bigint   'daily_impression_count',             default: 0
    t.integer  'load_count',                         default: 0
    t.integer  'integer',                            default: 0
    t.string   'promotion_type'
    t.float    'cost_per_impression'
    t.float    'cost_per_day'
    t.text     'coupon_email_body'
    t.string   'coupon_image'
    t.string   'sales_agent'
    t.integer  'digest_clicks',                      default: 0,     null: false
    t.integer  'digest_opens',                       default: 0,     null: false
    t.integer  'digest_emails',                      default: 0,     null: false
    t.datetime 'digest_metrics_updated'
    t.bigint    'location_id'
    t.index ['location_id'], name: 'index_promotion_banners_on_location_id'
    t.string "ad_service_id"
    t.index ["ad_service_id"], name: "index_promotion_banners_on_ad_service_id"
  end

  create_table 'promotions', id: :bigserial, force: :cascade do |t|
    t.string   'banner', limit: 255
    t.bigint   'content_id'
    t.text     'description'
    t.datetime 'created_at',                                  null: false
    t.datetime 'updated_at',                                  null: false
    t.bigint   'promotable_id'
    t.string   'promotable_type', limit: 255
    t.boolean  'paid', default: false
    t.bigint   'created_by_id'
    t.bigint   'updated_by_id'
    t.string   'share_platform'
    t.index ['content_id'], name: 'idx_16765_index_promotions_on_content_id', using: :btree
    t.index ['created_by_id'], name: 'idx_16765_index_promotions_on_created_by_id', using: :btree
  end

  create_table 'rewrites', id: :bigserial, force: :cascade do |t|
    t.string   'source',      limit: 255
    t.string   'destination', limit: 255
    t.bigint   'created_by_id'
    t.bigint   'updated_by_id'
    t.datetime 'created_at',              null: false
    t.datetime 'updated_at',              null: false
    t.index ['created_by_id'], name: 'idx_16828_index_rewrites_on_created_by_id', using: :btree
    t.index ['source'], name: 'idx_16828_index_rewrites_on_source', unique: true, using: :btree
    t.index ['updated_at'], name: 'idx_16828_index_rewrites_on_updated_at', using: :btree
  end

  create_table 'roles', id: :bigserial, force: :cascade do |t|
    t.string   'name', limit: 255
    t.bigint   'resource_id'
    t.string   'resource_type', limit: 255
    t.datetime 'created_at',                null: false
    t.datetime 'updated_at',                null: false
    t.index %w[name resource_type resource_id], name: 'idx_16837_index_roles_on_name_and_resource_type_and_resource_id', using: :btree
    t.index ['name'], name: 'idx_16837_index_roles_on_name', using: :btree
  end

  create_table 'schedules', id: :bigserial, force: :cascade do |t|
    t.text     'recurrence'
    t.bigint   'event_id'
    t.text     'description_override'
    t.string   'subtitle_override',    limit: 255
    t.string   'presenter_name',       limit: 255
    t.datetime 'created_at',                       null: false
    t.datetime 'updated_at',                       null: false
  end

  create_table 'sign_in_tokens', force: :cascade do |t|
    t.string   'token', null: false
    t.integer  'user_id'
    t.datetime 'created_at', null: false
    t.index ['token'], name: 'index_sign_in_tokens_on_token', using: :btree
    t.index ['user_id'], name: 'index_sign_in_tokens_on_user_id', using: :btree
  end

  create_table 'social_logins', force: :cascade do |t|
    t.integer  'user_id',    null: false
    t.string   'provider',   null: false
    t.string   'uid',        null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.json     'extra_info'
    t.index ['user_id'], name: 'index_social_logins_on_user_id', using: :btree
  end

  create_table 'subscriptions', force: :cascade do |t|
    t.integer  'user_id'
    t.integer  'listserv_id'
    t.datetime 'confirmed_at'
    t.datetime 'unsubscribed_at'
    t.boolean  'blacklist', default: false
    t.string   'subscription_details'
    t.string   'source'
    t.string   'email', null: false
    t.string   'confirmation_details'
    t.datetime 'created_at',                            null: false
    t.datetime 'updated_at',                            null: false
    t.string   'key',                                   null: false
    t.string   'name'
    t.string   'confirm_ip'
    t.string   'email_type', default: 'html'
    t.datetime 'mc_unsubscribed_at'
    t.index ['listserv_id'], name: 'index_subscriptions_on_listserv_id', using: :btree
    t.index ['user_id'], name: 'index_subscriptions_on_user_id', using: :btree
  end

  create_table 'user_bookmarks', force: :cascade do |t|
    t.integer  'user_id'
    t.integer  'content_id'
    t.integer  'event_instance_id'
    t.datetime 'created_at',                        null: false
    t.datetime 'updated_at',                        null: false
    t.boolean  'read', default: false
    t.datetime 'deleted_at'
    t.index ['content_id'], name: 'index_user_bookmarks_on_content_id', using: :btree
    t.index ['deleted_at'], name: 'index_user_bookmarks_on_deleted_at', using: :btree
    t.index ['user_id'], name: 'index_user_bookmarks_on_user_id', using: :btree
  end

  create_table 'users', id: :bigserial, force: :cascade do |t|
    t.string   'email',                  limit: 255, default: '',         null: false
    t.string   'encrypted_password',     limit: 255, default: '',         null: false
    t.string   'reset_password_token',   limit: 255
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.bigint   'sign_in_count', default: 0
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.string   'current_sign_in_ip',     limit: 255
    t.string   'last_sign_in_ip',        limit: 255
    t.datetime 'created_at',                                              null: false
    t.datetime 'updated_at',                                              null: false
    t.string   'name',                   limit: 255
    t.string   'confirmation_token',     limit: 255
    t.datetime 'confirmed_at'
    t.datetime 'confirmation_sent_at'
    t.string   'unconfirmed_email', limit: 255
    t.datetime 'nda_agreed_at'
    t.boolean  'agreed_to_nda', default: false
    t.string   'contact_phone',          limit: 255
    t.string   'contact_email',          limit: 255
    t.string   'contact_url',            limit: 255
    t.bigint   'location_id'
    t.string   'test_group', limit: 255, default: 'consumer'
    t.boolean  'muted', default: false
    t.string   'authentication_token',   limit: 255
    t.string   'avatar',                 limit: 255
    t.string   'public_id',              limit: 255
    t.boolean  'skip_analytics', default: false
    t.string   'temp_password'
    t.boolean  'archived', default: false
    t.string   'source'
    t.boolean  'receive_comment_alerts',             default: true
    t.boolean  'location_confirmed',                 default: false
    t.string   'fullname'
    t.string   'nickname'
    t.boolean  'epayment',                           default: false
    t.boolean  'w9',                                 default: false
    t.boolean  'has_had_bookmarks',                  default: false
    t.string   'mc_segment_id'
    t.string   'first_name'
    t.string   'last_name'
    t.string   'feed_card_size'
    t.boolean  'publisher_agreement_confirmed',      default: false
    t.datetime 'publisher_agreement_confirmed_at'
    t.string   'publisher_agreement_version'
    t.string   'handle'
    t.string   'mc_followers_segment_id'
    t.boolean  'email_is_public',                   default: false
    t.string   'background_image'
    t.string   'description'
    t.string   'website'
    t.string   'phone'
    t.index ['email'], name: 'idx_16858_index_users_on_email', unique: true, using: :btree
    t.index ['public_id'], name: 'idx_16858_index_users_on_public_id', unique: true, using: :btree
    t.index ['reset_password_token'], name: 'idx_16858_index_users_on_reset_password_token', unique: true, using: :btree
  end

  create_table 'users_roles', id: false, force: :cascade do |t|
    t.bigint 'user_id'
    t.bigint 'role_id'
    t.index %w[user_id role_id], name: 'idx_16873_index_users_roles_on_user_id_and_role_id', using: :btree
  end

  create_table 'x_content_campaigns', id: false, force: :cascade do |t|
    t.bigint   'id'
    t.string   'title',                     limit: 255
    t.string   'subtitle',                  limit: 255
    t.string   'authors',                   limit: 255
    t.text     'raw_content'
    t.bigint   'issue_id'
    t.bigint   'import_location_id'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.string   'copyright',                 limit: 255
    t.string   'guid',                      limit: 255
    t.datetime 'pubdate'
    t.string   'source_category',           limit: 255
    t.string   'topics',                    limit: 255
    t.string   'url',                       limit: 255
    t.string   'origin',                    limit: 255
    t.string   'language',                  limit: 255
    t.string   'page',                      limit: 255
    t.string   'authoremail',               limit: 255
    t.bigint   'organization_id'
    t.boolean  'quarantine'
    t.string   'doctype', limit: 255
    t.datetime 'timestamp'
    t.string   'contentsource', limit: 255
    t.bigint   'import_record_id'
    t.string   'source_content_id', limit: 255
    t.bigint   'parent_id'
    t.bigint   'content_category_id'
    t.boolean  'category_reviewed'
    t.boolean  'has_event_calendar'
    t.bigint   'channelized_content_id'
    t.boolean  'published'
    t.string   'channel_type', limit: 255
    t.bigint   'channel_id'
    t.bigint   'root_content_category_id'
    t.bigint   'view_count'
    t.bigint   'comment_count'
    t.bigint   'commenter_count'
    t.bigint   'created_by'
    t.bigint   'updated_by'
    t.bigint   'banner_click_count'
    t.text     'similar_content_overrides'
    t.bigint   'banner_ad_override'
    t.bigint   'root_parent_id'
    t.datetime 'deleted_at'
    t.boolean  'authors_is_created_by'
    t.string   'subscriber_mc_identifier'
    t.boolean  'biz_feed_public'
    t.datetime 'sunset_date'
    t.integer  'promote_radius'
    t.string   'ad_promotion_type'
    t.date     'ad_campaign_start'
    t.date     'ad_campaign_end'
    t.integer  'ad_max_impressions'
    t.string   'short_link'
    t.float    'ad_invoiced_amount'
    t.datetime 'first_served_at'
  end

  add_foreign_key 'campaigns', 'listservs'
  add_foreign_key 'contents', 'locations'
  add_foreign_key 'listserv_digests', 'listservs'
  add_foreign_key 'organization_content_tags', 'contents'
  add_foreign_key 'organization_content_tags', 'organizations'
  add_foreign_key 'organization_locations', 'locations'
  add_foreign_key 'organization_locations', 'organizations'
  add_foreign_key 'payment_recipients', 'organizations'
  add_foreign_key 'payment_recipients', 'users'
  add_foreign_key 'payments', 'contents'
  add_foreign_key 'profile_metrics', 'contents'
  add_foreign_key 'profile_metrics', 'locations'
  add_foreign_key 'profile_metrics', 'organizations'
  add_foreign_key 'profile_metrics', 'users'
  add_foreign_key 'sign_in_tokens', 'users'
  add_foreign_key 'social_logins', 'users'
  add_foreign_key 'subscriptions', 'listservs'
  add_foreign_key 'subscriptions', 'users'
  add_foreign_key 'user_bookmarks', 'contents'
  add_foreign_key 'user_bookmarks', 'users'
end