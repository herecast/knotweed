# == Schema Information
#
# Table name: content_sets
#
#  id                    :integer          not null, primary key
#  import_method         :string(255)
#  import_method_details :text
#  organization_id       :integer
#  name                  :string(255)
#  description           :text
#  notes                 :text
#  status                :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  start_date            :date
#  end_date              :date
#  ongoing               :boolean
#  format                :string(255)
#  publishing_frequency  :string(255)
#  developer_notes       :text
#  import_priority       :integer          default(1)
#  import_url_path       :string(255)
#

class ContentSet < ActiveRecord::Base
  belongs_to :organization
  has_many :import_jobs

  attr_accessible :description, :import_method, :import_method_details, 
                  :name, :notes, :organization_id, :status, :import_jobs_attributes,
                  :start_date, :end_date, :ongoing, :format, :publishing_frequency,
                  :developer_notes, :import_priority, :import_url_path


  FILE_IMPORT = "File Import"
  RSS_FEED = "RSS Feed"
  WEB_SCRAPE = "Web Scrape"
  POP3_EMAIL = "POP3 Email"
  MANUAL = "Manual"
  IMPORT_METHODS = [FILE_IMPORT, RSS_FEED, WEB_SCRAPE, POP3_EMAIL, MANUAL]
  IMPORT_PRIORITIES = 1..4

  FORMATS = ["json", "xml", "rtf", "pdf", "other", "txt", "doc", "docx", "html", "xls", "xlxx", "csv", "odt"]
  STATUSES = ["New", "Approved for Import", "Access Issues", "Processed", "Rejected", "Contact Source"]

  validates :import_method, inclusion: { in: IMPORT_METHODS }, allow_blank: true
  validates :format, inclusion: { in: FORMATS }, allow_blank: true
  validates :import_priority, inclusion: { in: IMPORT_PRIORITIES }
  validates_presence_of :organization
  validates_presence_of :name
  validates :publishing_frequency, inclusion: { in: Organization::FREQUENCY_OPTIONS }, allow_blank: true 

  before_save :set_publishing_frequency
  
  # for rails admin enum field
  def import_method_enum
    IMPORT_METHODS
  end

  # have publishing frequency fall back to organization.publishing_frequency
  def set_publishing_frequency
    unless publishing_frequency.present?
      update_attribute(:publishing_frequency, organization.publishing_frequency)
    end
  end

end
