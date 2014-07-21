# == Schema Information
#
# Table name: organizations
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  org_type   :string(255)
#  notes      :text
#

class Organization < ActiveRecord::Base

  has_and_belongs_to_many :contacts
  has_many :publications
  has_many :content_sets, through: :publications
  has_many :users
  has_many :parsers
  has_many :import_jobs
  has_many :locations, through: :publications

  attr_accessible :name, :org_type, :notes, :general, :tagline, :header, :header_cache,
                  :remove_header, :logo, :logo_cache, :removeLogo

  mount_uploader :header, ImageUploader
  mount_uploader :logo, ImageUploader

  serialize :general, Hash

  ORG_TYPE_OPTIONS = ["Ad Agency", "Business", "Community", "Educational", "Government", "Publisher"]

  validates_presence_of :name
  validates :org_type, inclusion: { in: ORG_TYPE_OPTIONS }, allow_blank: true

  def org_type_enum
    ORG_TYPE_OPTIONS
  end


end
