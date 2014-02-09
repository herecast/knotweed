class ContentSet < ActiveRecord::Base
  belongs_to :publication
  has_one :organization, through: :publication
  has_many :import_jobs

  attr_accessible :description, :import_method, :import_method_details, 
                  :name, :notes, :publication_id, :status, :import_jobs_attributes,
                  :start_date, :end_date, :ongoing, :format, :publishing_frequency,
                  :developer_notes


  FILE_IMPORT = "File Import"
  RSS_FEED = "RSS Feed"
  WEB_SCRAPE = "Web Scrape"
  POP3_EMAIL = "POP3 Email"
  MANUAL = "Manual"
  IMPORT_METHODS = [FILE_IMPORT, RSS_FEED, WEB_SCRAPE, POP3_EMAIL, MANUAL]

  FORMATS = ["json", "xml", "rtf", "pdf", "other"]
  STATUSES = ["New", "Approved for Import", "Access Issues", "Processed", "Rejected", "Contact Source"]

  validates :import_method, inclusion: { in: IMPORT_METHODS }, allow_blank: true
  validates :format, inclusion: { in: FORMATS }, allow_blank: true
  validates_presence_of :publication
  validates_presence_of :name
  validates :publishing_frequency, inclusion: { in: Publication::FREQUENCY_OPTIONS }, allow_blank: true 

  before_save :set_publishing_frequency
  
  # for rails admin enum field
  def import_method_enum
    IMPORT_METHODS
  end

  # have publishing frequency fall back to publication.publishing_frequency
  def set_publishing_frequency
    unless publishing_frequency.present?
      update_attribute(:publishing_frequency, publication.publishing_frequency)
    end
  end

end
