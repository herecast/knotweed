# == Schema Information
#
# Table name: publications
#
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  logo                 :string(255)
#  organization_id      :integer
#  website              :string(255)
#  publishing_frequency :string(255)
#  notes                :text
#  parent_id            :integer
#  category_override    :string(255)
#  tagline              :text
#  links                :text
#  social_media         :text
#  general              :text
#  header               :text
#  pub_type             :string(255)
#  display_attributes   :boolean          default: false
#

class Publication < ActiveRecord::Base
  
  has_many :issues
  belongs_to :organization

  belongs_to :parent, class_name: "Publication"
  has_many :children, class_name: "Publication", foreign_key: "parent_id"

  has_many :contents, inverse_of: :source, foreign_key: "source_id"

  has_many :content_sets

  # default images for contents
  has_many :images, as: :imageable, inverse_of: :imageable, dependent: :destroy

  has_and_belongs_to_many :contacts
  has_and_belongs_to_many :locations

  has_many :promotions, inverse_of: :publication
  
  attr_accessible :name, :logo, :logo_cache, :remove_logo, :organization_id,
                  :admin_contact_id, :tech_contact_id, :website, :publishing_frequency,
                  :notes, :images_attributes, :parent_id, :location_ids,
                  :remote_logo_url, :contact_ids, :category_override, :tagline, :links, 
                  :social_media, :general, :header, :header_cache, :remove_header,
                  :pub_type, :display_attributes
  
  mount_uploader :logo, ImageUploader
  mount_uploader :header, ImageUploader

  serialize :general, Hash
  serialize :links, Hash

  FREQUENCY_OPTIONS = ["Posts", "Daily", "Semiweekly", "Weekly", "Biweekly", "Semimonthly", "Monthly", "Bimonthly", "Quarterly", "Seasonally", "Semiannually", "Annually", "Biennially", "Ad Hoc"]

  validates :publishing_frequency, inclusion: { in: FREQUENCY_OPTIONS  }, allow_blank: true

  scope :alphabetical, order("name ASC")
  default_scope alphabetical

  PUB_TYPE_OPTIONS = ["Ad Agency", "Business", "Community", "Educational", "Government", "Publisher"]
  validates :pub_type, inclusion: { in: PUB_TYPE_OPTIONS }, allow_blank: true

  def publishing_frequency_enum
    FREQUENCY_OPTIONS
  end

  def self.parent_pubs
    ids = self.where("parent_id IS NOT NULL").select(:parent_id).uniq.map { |p| p.parent_id }
    self.find(ids)
  end

end
