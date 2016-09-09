# == Schema Information
#
# Table name: organizations
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  logo                  :string(255)
#  organization_id       :integer
#  website               :string(255)
#  notes                 :text(65535)
#  parent_id             :integer
#  org_type              :string(255)
#  can_reverse_publish   :boolean          default(FALSE)
#  can_publish_news      :boolean          default(FALSE)
#  subscribe_url         :string(255)
#  description           :text(65535)
#  profile_title         :string(255)
#  banner_ad_override    :string(255)
#  pay_rate_in_cents     :integer(8)
#  profile_title         :string
#  pay_directly          :boolean
#  can_publish_events    :boolean         default(FALSE)
#  can_publish_market    :boolean         default(FALSE)
#  can_publish_talk      :boolean         default(FALSE)
#  can_publish_ads       :boolean         default(FALSE)
#

class Organization < ActiveRecord::Base

  searchkick callbacks: :async, batch_size: 100, index_prefix: Figaro.env.stack_name

  def search_data
    {
      name: name,
      consumer_app_ids: consumer_apps.pluck(:id),
      content_category_ids: contents.pluck(:root_content_category_id).uniq
    }
  end

  resourcify
  belongs_to :parent, class_name: "Organization"
  has_many :children, class_name: "Organization", foreign_key: "parent_id"

  has_many :contents
  has_many :business_profiles, through: :contents

  has_many :content_sets

  # default images for contents
  has_many :images, as: :imageable, inverse_of: :imageable, dependent: :destroy

  has_many :users
  has_many :import_jobs
  has_many :issues
  has_many :business_locations

  has_and_belongs_to_many :contacts
  has_and_belongs_to_many :locations
  has_and_belongs_to_many :consumer_apps

  has_many :promotions, inverse_of: :organization

  attr_accessible :name, :logo, :logo_cache, :remove_logo, :organization_id,
                  :website, :notes, :images_attributes, :parent_id, :location_ids,
                  :remote_logo_url, :contact_ids, :org_type, :consumer_app_ids,
                  :can_publish_news, :subscribe_url, :description,
                  :banner_ad_override, :pay_rate_in_cents, :profile_title, :pay_directly,
                  :can_publish_events, :can_publish_market, :can_publish_talk,
                  :can_publish_ads

  mount_uploader :logo, ImageUploader

  scope :alphabetical, -> { order("organizations.name ASC") }
  default_scope { self.alphabetical }
  scope :get_children, ->(parent_ids) { where(parent_id: parent_ids) }

  ORG_TYPE_OPTIONS = ["Ad Agency", "Business", "Community", "Educational", "Government", "Publisher", 'Publication',
    'Blog']
  #validates :org_type, inclusion: { in: ORG_TYPE_OPTIONS }, allow_blank: true, allow_nil: true
  BLOGGER_PAY_RATES = [0, 5, 8]

  validates_uniqueness_of :name
  validates_presence_of :name
  validates :logo, :image_minimum_size => true

  def self.parent_pubs
    ids = self.where("parent_id IS NOT NULL").select(:parent_id, :name).uniq.map { |p| p.parent_id }
    self.where(id: ids)
  end

  def business_location_options
    business_locations.map{ |bl| [bl.select_option_label, bl.id] }
  end

  # returns an array of all organization records descended from this one
  #
  # @return [Array<Organization>] the descendants of the organization
  def get_all_children
    if children.present?
      response = children
      children.each do |c|
        response += c.get_all_children
      end
      response
    else
      []
    end
  end

  def remove_logo=(val)
    logo_will_change! if val
    super
  end

  def get_promotion
    promotion = Promotion.find_by(id: banner_ad_override)
    if promotion.try(:promotable).try(:class) == PromotionBanner
      banner = promotion.promotable
    else
      banner = nil
    end
    select_score = nil
    select_method = 'sponsored_content'
    banner.present? ? [banner, select_score, select_method] : PromotionBanner.get_random_promotion
  end

  ransacker :include_child_organizations
end
