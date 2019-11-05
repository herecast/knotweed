# frozen_string_literal: true
# == Schema Information
#
# Table name: contents
#
#  id                        :bigint(8)        not null, primary key
#  title                     :string(255)
#  subtitle                  :string(255)
#  authors                   :string(255)
#  raw_content               :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  pubdate                   :datetime
#  url                       :string(255)
#  origin                    :string(255)
#  page                      :string(255)
#  authoremail               :string(255)
#  organization_id           :bigint(8)
#  timestamp                 :datetime
#  parent_id                 :bigint(8)
#  has_event_calendar        :boolean          default(FALSE)
#  channelized_content_id    :bigint(8)
#  channel_type              :string(255)
#  channel_id                :bigint(8)
#  root_content_category_id  :bigint(8)
#  view_count                :bigint(8)        default(0)
#  comment_count             :bigint(8)        default(0)
#  commenter_count           :bigint(8)        default(0)
#  created_by_id             :bigint(8)
#  updated_by_id             :bigint(8)
#  banner_click_count        :bigint(8)        default(0)
#  similar_content_overrides :text
#  banner_ad_override        :bigint(8)
#  root_parent_id            :bigint(8)
#  deleted_at                :datetime
#  authors_is_created_by     :boolean          default(FALSE)
#  subscriber_mc_identifier  :string
#  biz_feed_public           :boolean
#  sunset_date               :datetime
#  promote_radius            :integer
#  ad_promotion_type         :string
#  ad_campaign_start         :date
#  ad_campaign_end           :date
#  ad_max_impressions        :integer
#  short_link                :string
#  ad_invoiced_amount        :float
#  first_served_at           :datetime
#  removed                   :boolean          default(FALSE)
#  ad_invoice_paid           :boolean          default(FALSE)
#  ad_commission_amount      :float
#  ad_commission_paid        :boolean          default(FALSE)
#  ad_services_amount        :float
#  ad_services_paid          :boolean          default(FALSE)
#  ad_sales_agent            :integer
#  ad_promoter               :integer
#  latest_activity           :datetime
#  has_future_event_instance :boolean
#  alternate_title           :string
#  alternate_organization_id :integer
#  alternate_authors         :string
#  alternate_text            :string
#  alternate_image_url       :string
#  location_id               :integer
#  mc_campaign_id            :string
#  ad_service_id             :string
#  content_category          :string
#
# Indexes
#
#  idx_16527_authors                                     (authors)
#  idx_16527_index_contents_on_authoremail               (authoremail)
#  idx_16527_index_contents_on_channel_id                (channel_id)
#  idx_16527_index_contents_on_channel_type              (channel_type)
#  idx_16527_index_contents_on_channelized_content_id    (channelized_content_id)
#  idx_16527_index_contents_on_created_by                (created_by_id)
#  idx_16527_index_contents_on_parent_id                 (parent_id)
#  idx_16527_index_contents_on_root_content_category_id  (root_content_category_id)
#  idx_16527_index_contents_on_root_parent_id            (root_parent_id)
#  idx_16527_pubdate                                     (pubdate)
#  idx_16527_source_id                                   (organization_id)
#  idx_16527_title                                       (title)
#  index_contents_on_ad_service_id                       (ad_service_id)
#  index_contents_on_content_category                    (content_category)
#  index_contents_on_location_id                         (location_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#

require 'fileutils'
require 'builder'
include ActionView::Helpers::TextHelper
class Content < ActiveRecord::Base
  extend Enumerize
  include Auditable
  include Incrementable
  include Searchable

  CONTENT_CATEGORIES = %w(talk_of_the_town news campaign market event)

  before_create :set_latest_activity
  def set_latest_activity
    self.latest_activity = pubdate.present? ? pubdate : Time.current
  end

  before_save :conditionally_update_latest_activity
  def conditionally_update_latest_activity
    if content_category == 'news' && will_save_change_to_pubdate?
      self.latest_activity = pubdate
    end
  end

  searchkick callbacks: :async,
             batch_size: 750,
             index_prefix: Figaro.env.searchkick_index_prefix,
             searchable: %i[content title subtitle caster_handle caster_name],
             settings: {
               analysis: {
                 analyzer: {
                   # @TODO! This changes in newer searchkick versions.
                   # see: https://github.com/ankane/searchkick/blob/master/lib/searchkick/index_options.rb
                   searchkick_index: {
                     char_filter: %w[html_strip ampersand]
                   }
                 }
               }
             }

  scope :search_import, lambda {
    includes(:promotions,
             :images,
             :created_by,
             :location,
             children: [:created_by])
      .where('organization_id NOT IN (4,5,328) OR organization_id IS NULL')
      .where('content_category IS NOT NULL')
      .where('raw_content IS NOT NULL')
      .where("raw_content != ''")
  }

  def search_serializer
    SearchIndexing::ContentSerializer
  end

  def search_data
    search_serializer.new(self).serializable_hash
  end

  def view_count_data
    { view_count: view_count }
  end

  def banner_click_count_data
    { banner_click_count: banner_click_count }
  end

  def like_count_data
    { like_count: like_count }
  end

  def should_index?
    deleted_at.blank? && raw_content.present?
  end

  after_commit :reindex_associations_async
  def reindex_associations_async
    if channel.present? && channel.is_a?(Event)
      channel.event_instances.each{ |ei| ei.reindex(mode: :async) }
    end
  end

  belongs_to :location
  belongs_to :caster, foreign_key: 'created_by_id'

  has_many :content_reports
  has_many :payments

  has_many :profile_metrics, dependent: :destroy

  validate :if_ad_promotion_type_sponsored_must_have_ad_max_impressions
  validates :ad_invoiced_amount, numericality: { greater_than: 0 }, if: -> { ad_invoiced_amount.present? }
  validates :ad_commission_amount, numericality: { greater_than: 0 }, if: -> { ad_commission_amount.present? }
  validates :ad_services_amount, numericality: { greater_than: 0 }, if: -> { ad_services_amount.present? }

  has_many :organization_content_tags, dependent: :destroy
  has_many :organizations, through: :organization_content_tags

  has_many :images, -> { order('images.primary DESC') }, as: :imageable, inverse_of: :imageable, dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true

  belongs_to :organization
  accepts_nested_attributes_for :organization
  delegate :name, to: :organization, prefix: true, allow_nil: true

  belongs_to :parent, class_name: 'Content'
  belongs_to :root_parent, class_name: name
  has_many :children, class_name: 'Content', foreign_key: 'parent_id'
  has_many :comments

  has_many :promotions
  has_many :user_bookmarks

  # mapping to content record that represents the channelized content
  belongs_to :channelized_content, class_name: 'Content'
  has_one :sales_agent, class_name: 'User', primary_key: 'ad_sales_agent', foreign_key: 'id'
  has_one :promoter, class_name: 'User', primary_key: 'ad_promoter', foreign_key: 'id'

  attr_accessor :tier # this is not stored on the database, but is used to generate a tiered tree
  # for the API

  validates_presence_of :raw_content, :title, if: :is_event?
  validates_presence_of :raw_content, :title, if: :is_market_post?
  validates_presence_of :organization_id, :title, :ad_promotion_type, :ad_campaign_start, :ad_campaign_end, if: :is_campaign?

  # this has to be after save to accomodate the situation
  # where we are creating new content with no parent
  after_save :set_root_parent_id

  after_create :hide_campaign_from_public_view

  # channel relationships
  belongs_to :channel, polymorphic: true, inverse_of: :content

  # THESE ARE JUST SEMI-FAKE ASSOCIATIONS FOR RANSACK TO USE FOR CONTENTS#INDEX
  # DO NOT USE OTHERWISE
  belongs_to :event, foreign_key: 'channel_id'
  accepts_nested_attributes_for :event, allow_destroy: true
  has_many :event_instances, through: :event
  belongs_to :market_post, foreign_key: 'channel_id'
  accepts_nested_attributes_for :market_post, allow_destroy: true

  scope :events, lambda { where(content_category: 'event') }
  scope :market_posts, -> { where(channel_type: 'MarketPost') }

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :not_removed, -> { where(removed: false) }
  scope :only_categories, lambda { |names| where('content_category IN (?)', names) }

  scope :ad_campaign_active, lambda { |date = Date.current|
                               where('ad_campaign_start <= ?', date)
                                 .where('ad_campaign_end >= ?', date)
                             }

  scope(:ad_campaigns_for_reports, lambda do |window_start = 8.days.ago, window_end = Date.current|
    where(content_category: 'campaign')
      .where("(ad_campaign_start >= :window_start AND ad_campaign_start < :window_end) OR
          (ad_campaign_end >= :window_start AND ad_campaign_end < :window_end) OR
          (ad_campaign_start <= :window_start AND ad_campaign_end >= :window_end)",
        window_start: window_start,
        window_end: window_end)
      .includes(:promotions)
      .where.not(promotions: { id: nil })
  end)

  UGC_ORIGIN = 'UGC'

  UGC_PROCESSES = {
    'create' => {
      'event' => Ugc::CreateEvent,
      'market' => Ugc::CreateMarket,
      'news' => Ugc::CreateNews,
    },
    'update' => {
      'event' => Ugc::UpdateEvent,
      'market' => Ugc::UpdateMarket,
      'news' => Ugc::UpdateNews,
    }
  }.freeze

  CATEGORIES = %w[beta_talk business campaign discussion event for_free lifestyle
                  local_news nation_world offered presentation recommendation
                  sale_event sports wanted].freeze

  # ensure that we never save titles with leading/trailing whitespace
  def title=(t)
    write_attribute(:title, t.to_s.strip)
  end

  def primary_image
    images.find(&:primary) || images.min_by(&:id)
  end

  def primary_image=(image)
    # make sure all other images are secondary
    images.where(primary: true).each do |i|
      i.update_attribute(:primary, false) unless i == image
    end
    image.update_attribute(:primary, true)
  end

  # holdover from when we used to use processed_content by preference.
  # Seemed easier to keep this method, but just make it point directly to raw content
  # than to remove references to the method altogether
  def content
    raw_content
  end

  def content_type
    if content_category == 'talk_of_the_town'
      'talk'
    else
      content_category
    end
  end

  def set_root_parent_id
    # we don't want to be calling find_root_parent every time because it's costly,
    # so we rely on whether or not the parent_id changed as that's the only way -- within
    # a single transaction -- that root_parent_id could've changed
    if saved_change_to_parent_id? || parent_id.nil? # the latter part of this conditional covers creating
      # new content that doesn't have a parent
      update_column(:root_parent_id, find_root_parent.id)
    end
  end

  # for threaded contents
  # returns the original content of the thread by recursively iterating through parent
  # association
  def find_root_parent
    if parent.present?
      parent.find_root_parent
    else
      self
    end
  end

  # Creates sanitized version of title - at this point, just stripping out listerv towns
  def sanitized_title
    if title.present?
      new_title = title.gsub(/\[[^\]]+\]/, '').strip
      new_title.present? ? new_title : "Post by #{author_name}"
    end
  end

  # Creates HTML-annotated, sanitized version of the raw_content that should be
  # as display-ready as possible
  def sanitized_content
    if raw_content.nil?
      raw_content
    else
      ugc_sanitized_content
    end
  end

  def ugc_sanitized_content
    UgcSanitizer.call(raw_content)
  end

  def sanitized_content=(new_content)
    self.raw_content = new_content
  end

  # returns true if content has attached event
  def is_event?
    channel_type.present? && (channel_type == 'Event')
  end

  def is_market_post?
    channel_type.present? && (channel_type == 'MarketPost')
  end

  def is_campaign?
    content_category == 'campaign'
  end

  # Retrieves similar content (as configured in similar_content_overrides for sponsored content or determined by
  # ElasticSearch similarity and returns array of related content objects
  #
  # @param num_similar [Integer] number of results to return
  # @return [Array<Content>] list of similar content
  def similar_content(num_similar)
    c = similar(
      fields: %i[title content location_id],
      where: {
        pubdate: 5.years.ago..Time.current,
        removed: { not: true },
        has_future_event_instance: { not: false },
        channel_type: { not: 'Comment' },
        origin: UGC_ORIGIN
      },
      load: false,
      limit: num_similar
    )
    c
  end

  def uri
    CGI.escape(BASE_URI + "/#{id}")
  end

  def increment_view_count!
    # check if content is published before incrementing
    if pubdate.present? && (pubdate <= Time.now)
      unless User.current.try(:skip_analytics) && content_category == 'news'
        increment_integer_attr!(:view_count)
      end
    end
  end

  # typically returns author information by checking `created_by` if available
  # or falling back to `authors` otherwise. For UGC News content, we reverse the conditional.
  #
  # @return [String] the author's name
  def author_name
    if is_news?
      if authors_is_created_by?
        created_by.try(:name)
      else
        authors
      end
    else
      created_by.present? ? created_by.name : authors
    end
  end

  # helper that checks if content is News UGC or not
  #
  # @return [Boolean] true if is news ugc
  def is_news_ugc?
    (origin == UGC_ORIGIN) && content_category == 'news'
  end

  def is_news?
    content_category == 'news'
  end

  def current_daily_report(current_date = Date.current)
    content_reports.where('report_date >= ?', current_date).take
  end

  def find_or_create_daily_report(current_date = Date.current)
    current_daily_report(current_date) || content_reports.create!(report_date: current_date)
  end

  def ok_to_send_alert?
    created_by&.receive_comment_alerts && created_by.present?
  end

  def embedded_ad?
    !!(organization.present? && organization.embedded_ad)
  end

  def built_view_count
    if content_category == 'campaign'
      promotions.includes(:promotable).first.try(:promotable).try(:impression_count)
    elsif parent.present?
      parent.view_count
    else
      view_count
    end
  end

  def set_event_latest_activity
    if channel_type == 'Event'
      update_attribute(
        :latest_activity,
        event_latest_activity
      )
    end
  end

  def abridged_comments
    comments.where('pubdate IS NOT NULL AND deleted_at IS NULL')
            .order(pubdate: :desc)
            .take(6)
  end

  def should_notify_subscribers?
    mc_campaign_id.nil? && caster.active_follower_count > 0
  end

  def like_count
    user_bookmarks.count
  end

  private

  def event_latest_activity
    one_day_before_event = channel.event_instances.first.start_date - 1.day
    one_day_before_event < Time.current ? Time.current : one_day_before_event
  end

  def if_ad_promotion_type_sponsored_must_have_ad_max_impressions
    if ad_promotion_type == PromotionBanner::SPONSORED && ad_max_impressions.nil?
      errors.add(:ad_max_impressions, 'For ad_promotion_type Sponsored, ad_max_impressions must be populated')
    end
  end

  def hide_campaign_from_public_view
    if content_category == 'campaign'
      update_attribute(:biz_feed_public, false)
    end
  end
end
