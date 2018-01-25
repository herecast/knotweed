# == Schema Information
#
# Table name: organizations
#
#  id                      :integer          not null, primary key
#  name                    :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  logo                    :string(255)
#  organization_id         :integer
#  website                 :string(255)
#  notes                   :text
#  parent_id               :integer
#  org_type                :string(255)
#  can_reverse_publish     :boolean          default(FALSE)
#  can_publish_news        :boolean          default(FALSE)
#  subscribe_url           :string(255)
#  description             :text
#  banner_ad_override      :string(255)
#  profile_title           :string(255)
#  pay_directly            :boolean          default(FALSE)
#  can_publish_events      :boolean          default(FALSE)
#  can_publish_market      :boolean          default(FALSE)
#  can_publish_talk        :boolean          default(FALSE)
#  can_publish_ads         :boolean          default(FALSE)
#  profile_image           :string(255)
#  background_image        :string(255)
#  profile_ad_override     :string(255)
#  twitter_handle          :string
#  custom_links            :jsonb
#  biz_feed_active         :boolean          default(FALSE)
#  ad_sales_agent          :string
#  ad_contact_nickname     :string
#  ad_contact_fullname     :string
#  profile_sales_agent     :string
#  blog_contact_name       :string
#  embedded_ad             :boolean          default(FALSE)
#  certified_storyteller   :boolean          default(FALSE)
#  services                :string
#  contact_card_active     :boolean          default(TRUE)
#  description_card_active :boolean          default(TRUE)
#  hours_card_active       :boolean          default(TRUE)
#  pay_for_content         :boolean          default(FALSE)
#  special_link_url        :string
#  special_link_text       :string
#  certified_social        :boolean          default(FALSE)
#  desktop_image           :string
#
# Indexes
#
#  idx_16739_index_publications_on_name  (name) UNIQUE
#

class Organization < ActiveRecord::Base
  ORG_TYPE_OPTIONS = ["Business", "Publisher", 'Publication', 'Blog']

  LISTSERV_ORG_ID = 447
  LISTSERV_ORG_NAME = "Listserv"

  searchkick callbacks: :async,
    batch_size: 100,
    index_prefix: Figaro.env.searchkick_index_prefix,
    searchable: [:name]

  ransacker :show_news_publishers

  def search_data
    {
      name: name,
      org_type: org_type,
      biz_feed_active: biz_feed_active,
      consumer_app_ids: consumer_apps.pluck(:id),
      content_category_ids: contents.pluck(:root_content_category_id).uniq,
      certified_storyteller: certified_storyteller,
      certified_social: certified_social
    }
  end

  resourcify
  belongs_to :parent, class_name: "Organization"
  has_many :children, class_name: "Organization", foreign_key: "parent_id"

  has_many :contents
  has_many :business_profiles, through: :contents

  has_many :organization_content_tags
  has_many :tagged_contents, through: :organization_content_tags

  has_many :content_sets

  # default images for contents
  has_many :images, as: :imageable, inverse_of: :imageable, dependent: :destroy

  has_many :users
  has_many :import_jobs
  has_many :issues
  has_many :business_locations
  has_many :venue_events, through: :business_locations, source: :events
  has_many :organization_locations
  accepts_nested_attributes_for :organization_locations, allow_destroy: true
  has_many :locations, through: :organization_locations
  has_many :base_locations, -> { where('"organization_locations"."location_type" = \'base\'') },
           through: :organization_locations, source: :location

  has_and_belongs_to_many :contacts
  has_and_belongs_to_many :consumer_apps

  has_many :promotions, inverse_of: :organization

  after_update :trigger_content_reindex!, if: :name_changed?

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
                                 :remove_desktop_image!

  scope :alphabetical, -> { order("organizations.name ASC") }
  default_scope { self.alphabetical }
  scope :get_children, ->(parent_ids) { where(parent_id: parent_ids) }
  scope :descendants_of, ->(org_ids) {
    children_ids = self.get_children(org_ids).pluck(:id)
    if children_ids.present?
      children_descendant_ids = self.descendants_of(children_ids).pluck(:id)
      self.where(id: children_ids + children_descendant_ids)
    else
      self.none
    end
  }
  scope :news_publishers, -> { where(org_type: %w[Publisher Publication Blog]) }

  #validates :org_type, inclusion: { in: ORG_TYPE_OPTIONS }, allow_blank: true, allow_nil: true

  validates_uniqueness_of :name
  validates_presence_of :name
  validates :logo, :image_minimum_size => true
  validate :twitter_handle_format

  def self.parent_pubs
    ids = self.where("parent_id IS NOT NULL").select(:parent_id, :name).uniq.map { |p| p.parent_id }
    self.where(id: ids)
  end

  def base_locations=locs
    locs.each do |l|
      OrganizationLocation.find_or_initialize_by(
        organization: self,
        location: l
      ).base!
    end
  end

  def business_location_options
    business_locations.map{ |bl| [bl.select_option_label, bl.id] }
  end

  # returns an array of all organization records descended from this one
  #
  # @return [Array<Organization>] the descendants of the organization
  def get_all_children
    self.class.descendants_of(self.id)
  end

  def remove_logo=(val)
    logo_will_change! if val
    super
  end

  # selects an ad from the array of profile ad override options
  def get_profile_ad_override_id
    profile_ad_override.split(',').sample.to_i if profile_ad_override.present?
  end

  ransacker :include_child_organizations

  def trigger_content_reindex!
    ReindexOrganizationContentJob.perform_later self
  end

  def has_business_profile?
    contents.where(channel_type: 'BusinessProfile').present?
  end

  def venue_event_ids
    # remove conditional after rails 5 upgrade
    association(:venue_events).loaded? ? venue_events.map(&:id) : venue_events.pluck(:id)
  end

  private

  def twitter_handle_format
    twitter_handle_regex = /^@([A-Za-z0-9_]+)$/
    unless twitter_handle.blank? || !!twitter_handle_regex.match(twitter_handle)
      errors.add(:twitter_handle, "Twitter handle must start with @. The handle may have letters, numbers and underscores, but no spaces.")
    end
  end
end
