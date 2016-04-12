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
#  notes                 :text
#  parent_id             :integer
#  category_override     :string(255)
#  org_type              :string(255)
#  display_attributes    :boolean          default(FALSE)
#  reverse_publish_email :string(255)
#  can_reverse_publish   :boolean          default(FALSE)
#

class Organization < ActiveRecord::Base
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
  has_and_belongs_to_many :external_categories,
        class_name: "ContentCategory"

  has_many :promotions, inverse_of: :organization

  attr_accessible :name, :logo, :logo_cache, :remove_logo, :organization_id,
                  :website, :notes, :images_attributes, :parent_id, :location_ids,
                  :remote_logo_url, :contact_ids, :category_override,
                  :org_type, :display_attributes, :reverse_publish_email,
                  :consumer_app_ids, :external_category_ids, :can_publish_news
  
  mount_uploader :logo, ImageUploader

  scope :alphabetical, -> { order("organizations.name ASC") }
  default_scope { self.alphabetical }

  ORG_TYPE_OPTIONS = ["Ad Agency", "Business", "Community", "Educational", "Government", "Publisher", 'Publication']
  #validates :org_type, inclusion: { in: ORG_TYPE_OPTIONS }, allow_blank: true, allow_nil: true

  validates_uniqueness_of :name
  validates_uniqueness_of :reverse_publish_email, allow_nil: true, allow_blank: true
  validates_presence_of :name

  def self.parent_pubs
    ids = self.where("parent_id IS NOT NULL").select(:parent_id).uniq.map { |p| p.parent_id }
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
end
