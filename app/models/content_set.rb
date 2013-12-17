class ContentSet < ActiveRecord::Base
  belongs_to :publication
  has_many :import_jobs

  attr_accessible :description, :import_method, :import_method_details, 
                  :name, :notes, :publication_id, :status, :import_jobs_attributes

  FILE_IMPORT = "File Import"
  RSS_FEED = "RSS Feed"
  WEB_SCRAPE = "Web Scrape"
  POP3_EMAIL = "POP3 Email"
  MANUAL = "Manual"
  IMPORT_METHODS = [FILE_IMPORT, RSS_FEED, WEB_SCRAPE, POP3_EMAIL, MANUAL]

  validates :import_method, inclusion: { in: IMPORT_METHODS }
  validates_presence_of :publication
  validates_presence_of :name
  
  # for rails admin enum field
  def import_method_enum
    IMPORT_METHODS
  end

end
