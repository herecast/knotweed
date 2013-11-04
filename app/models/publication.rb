class Publication < ActiveRecord::Base
  
  has_many :issues
  belongs_to :organization
  has_many :contents, inverse_of: :source, foreign_key: "source_id"

  belongs_to :admin_contact, class_name: "Contact"
  belongs_to :tech_contact, class_name: "Contact"
  
  attr_accessible :name, :logo, :logo_cache, :remove_logo, :organization_id,
                  :admin_contact_id, :tech_contact_id, :website, :publishing_frequency,
                  :notes
  
  mount_uploader :logo, ImageUploader

  FREQUENCY_OPTIONS = ["Daily", "Weekly", "Ad Hoc"]

  validates :publishing_frequency, inclusion: { in: FREQUENCY_OPTIONS  }, allow_nil: true

  def publishing_frequency_enum
    FREQUENCY_OPTIONS
  end

end
