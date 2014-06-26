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
  
  attr_accessible :name, :logo, :logo_cache, :remove_logo, :organization_id,
                  :admin_contact_id, :tech_contact_id, :website, :publishing_frequency,
                  :notes, :images_attributes, :parent_id, :location_ids,
                  :remote_logo_url, :contact_ids, :category_override
  
  mount_uploader :logo, ImageUploader

  FREQUENCY_OPTIONS = ["Posts", "Daily", "Semiweekly", "Weekly", "Biweekly", "Semimonthly", "Monthly", "Bimonthly", "Quarterly", "Seasonally", "Semiannually", "Annually", "Biennially", "Ad Hoc"]

  validates :publishing_frequency, inclusion: { in: FREQUENCY_OPTIONS  }, allow_blank: true

  rails_admin do
    edit do
      exclude_fields :contents, :issues
    end
    show do
      exclude_fields :contents, :issues
    end
  end

  scope :alphabetical, order("name ASC")
  default_scope alphabetical

  def publishing_frequency_enum
    FREQUENCY_OPTIONS
  end

  def self.parent_pubs
    ids = self.where("parent_id IS NOT NULL").select(:parent_id).uniq.map { |p| p.parent_id }
    self.find(ids)
  end

end
