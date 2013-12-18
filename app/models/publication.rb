class Publication < ActiveRecord::Base
  
  has_many :issues
  belongs_to :organization

  belongs_to :parent, class_name: "Publication"
  has_many :children, class_name: "Publication", foreign_key: "parent_id"

  has_many :contents, inverse_of: :source, foreign_key: "source_id"

  has_many :content_sets

  # default images for contents
  has_many :images, as: :imageable, inverse_of: :imageable, dependent: :destroy

  belongs_to :admin_contact, class_name: "Contact"
  belongs_to :tech_contact, class_name: "Contact"

  has_and_belongs_to_many :locations
  
  attr_accessible :name, :logo, :logo_cache, :remove_logo, :organization_id,
                  :admin_contact_id, :tech_contact_id, :website, :publishing_frequency,
                  :notes, :images_attributes, :parent_id, :location_ids
  
  mount_uploader :logo, ImageUploader

  FREQUENCY_OPTIONS = ["Daily", "Weekly", "Ad Hoc", "Quarterly", "Posts"]

  validates :publishing_frequency, inclusion: { in: FREQUENCY_OPTIONS  }, allow_nil: true

  def publishing_frequency_enum
    FREQUENCY_OPTIONS
  end

end
