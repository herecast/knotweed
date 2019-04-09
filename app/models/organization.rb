# frozen_string_literal: true

# == Schema Information
#
# Table name: organizations
#
#  id                       :bigint(8)        not null, primary key
#  name                     :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  logo                     :string(255)
#  organization_id          :bigint(8)
#  website                  :string(255)
#  notes                    :text
#  parent_id                :bigint(8)
#  org_type                 :string(255)
#  can_reverse_publish      :boolean          default(FALSE)
#  can_publish_news         :boolean          default(FALSE)
#  description              :text
#  banner_ad_override       :string(255)
#  pay_directly             :boolean          default(FALSE)
#  profile_image            :string(255)
#  background_image         :string(255)
#  twitter_handle           :string
#  custom_links             :jsonb
#  biz_feed_active          :boolean          default(FALSE)
#  ad_sales_agent           :string
#  ad_contact_nickname      :string
#  ad_contact_fullname      :string
#  profile_sales_agent      :string
#  certified_storyteller    :boolean          default(FALSE)
#  services                 :string
#  contact_card_active      :boolean          default(TRUE)
#  description_card_active  :boolean          default(TRUE)
#  hours_card_active        :boolean          default(TRUE)
#  pay_for_content          :boolean          default(FALSE)
#  special_link_url         :string
#  special_link_text        :string
#  certified_social         :boolean          default(FALSE)
#  desktop_image            :string
#  archived                 :boolean          default(FALSE)
#  feature_notification_org :boolean          default(FALSE)
#  standard_ugc_org         :boolean          default(FALSE)
#  calendar_view_first      :boolean          default(FALSE)
#  calendar_card_active     :boolean          default(FALSE)
#  embedded_ad              :boolean          default(TRUE)
#  digest_id                :integer
#  reminder_campaign_id     :string
#  mc_segment_id            :string
#
# Indexes
#
#  idx_16739_index_publications_on_name  (name) UNIQUE
#

class Organization < ActiveRecord::Base
  ORG_TYPE_OPTIONS = %w[Business Publisher Publication Blog].freeze

  searchkick callbacks: :async,
             batch_size: 1000,
             index_prefix: Figaro.env.searchkick_index_prefix,
             searchable: %i[name description]

  ransacker :show_news_publishers

  def search_data
    {
      name: name,
      org_type: org_type,
      biz_feed_active: biz_feed_active,
      content_category_ids: contents_root_content_category_ids_only.map(&:root_content_category_id).uniq,
      certified_storyteller: certified_storyteller,
      certified_social: certified_social,
      archived: archived,
      description: description
    }
  end

  scope :search_import, lambda {
    includes(
      :contents_root_content_category_ids_only
    )
  }

  has_many :contents_root_content_category_ids_only,
           -> { select('contents.root_content_category_id, contents.organization_id') },
           primary_key: :id,
           foreign_key: :organization_id,
           class_name: :Content

  resourcify
  belongs_to :parent, class_name: 'Organization'
  has_many :children, class_name: 'Organization', foreign_key: 'parent_id'

  has_many :contents
  has_many :business_profiles, through: :contents
  has_many :organization_subscriptions
  has_many :organization_hides

  has_many :organization_content_tags
  has_many :tagged_contents, through: :organization_content_tags

  # default images for contents
  has_many :images, as: :imageable, inverse_of: :imageable, dependent: :destroy

  has_many :users
  has_many :business_locations
  has_many :venue_events, through: :business_locations, source: :events
  has_many :organization_locations
  accepts_nested_attributes_for :organization_locations, allow_destroy: true
  has_many :locations, through: :organization_locations
  has_many :base_locations, -> { where('"organization_locations"."location_type" = \'base\'') },
           through: :organization_locations, source: :location
  has_many :consumer_active_base_locations, lambda {
    where('"organization_locations"."location_type" = \'base\' and consumer_active = true')
  },
           through: :organization_locations, source: :location

  after_commit :trigger_content_reindex_if_name_or_profile_image_changed!, on: :update

  mount_uploader :logo, ImageUploader
  mount_uploader :profile_image, ImageUploader
  mount_uploader :background_image, ImageUploader
  mount_uploader :desktop_image, ImageUploader
  skip_callback :commit, :after, :remove_previously_stored_logo,
                :remove_previously_stored_profile_image,
                :remove_previously_stored_background_image,
                :remove_previously_stored_desktop_image,
                :remove_logo!,
                :remove_profile_image!,
                :remove_background_image!,
                :remove_desktop_image!, raise: false

  scope :alphabetical, -> { order('organizations.name ASC') }
  default_scope { alphabetical }
  scope :get_children, ->(parent_ids) { where(parent_id: parent_ids) }
  scope :descendants_of, lambda { |org_ids|
    children_ids = get_children(org_ids).pluck(:id)
    if children_ids.present?
      children_descendant_ids = descendants_of(children_ids).pluck(:id)
      where(id: children_ids + children_descendant_ids)
    else
      none
    end
  }
  scope :news_publishers, -> { where(org_type: %w[Publisher Publication Blog]) }
  scope :not_archived, -> { where(archived: [false, nil]) }

  # validates :org_type, inclusion: { in: ORG_TYPE_OPTIONS }, allow_blank: true, allow_nil: true

  validates_uniqueness_of :name
  validates_presence_of :name
  validates :logo, image_minimum_size: true
  validate :twitter_handle_format

  def self.parent_pubs
    ids = where('parent_id IS NOT NULL').select(:parent_id, :name).distinct.map(&:parent_id)
    where(id: ids)
  end

  def promotions
    Promotion.where('content_id IN (select id from contents where contents.organization_id = ?)', id)
  end

  def base_locations=(locs)
    locs.each do |l|
      OrganizationLocation.find_or_initialize_by(
        organization: self,
        location: l
      ).base!
    end
  end

  # returns an array of all organization records descended from this one
  #
  # @return [Array<Organization>] the descendants of the organization
  def get_all_children
    self.class.descendants_of(id)
  end

  def remove_logo=(val)
    logo_will_change! if val
    super
  end

  ransacker :include_child_organizations

  def trigger_content_reindex!
    ReindexAssociatedContentJob.perform_later self
  end

  def has_business_profile?
    contents.where(channel_type: 'BusinessProfile').present?
  end

  def profile_link
    "https://#{Figaro.env.default_host}/profile/#{id}"
  end

  def mc_segment_name
    "#{id}-organization-segment"
  end

  def active_subscriber_count
    organization_subscriptions.active.count
  end

  # counts MarketPost, News, and Events -- not comments or ads
  def counted_posts
    contents
      .not_removed
      .where('pubdate IS NOT NULL and pubdate < ?', Time.current)
      .where("(channel_type != 'BusinessProfile' AND channel_type != 'Comment') OR channel_type IS NULL")
      .where('content_category_id != ?', ContentCategory.find_or_create_by(name: 'campaign'))
      .where('biz_feed_public = true OR biz_feed_public IS NULL')
  end

  def post_count
    counted_posts.count
  end

  private

  def trigger_content_reindex_if_name_or_profile_image_changed!
    if previous_changes.key?(:name) || previous_changes.key?(:profile_image)
      ReindexAssociatedContentJob.perform_later self
    end
  end

  def twitter_handle_format
    twitter_handle_regex = /^@([A-Za-z0-9_]+)$/
    unless twitter_handle.blank? || !!twitter_handle_regex.match(twitter_handle)
      errors.add(:twitter_handle, 'Twitter handle must start with @. The handle may have letters, numbers and underscores, but no spaces.')
    end
  end
end
