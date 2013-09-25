class ImportJob < ActiveRecord::Base

  belongs_to :organization
  belongs_to :parser
  
  validates_presence_of :organization
  
  attr_accessible :config, :last_run_at, :name, :parser_id, :source_path, :type, :organization_id
  
  after_create :enqueue_job
  
  # delayed job action
  # 
  # determines the process needed to run the import job (parser, scraping, etc.)
  # and activates it
  def perform
    # do nothing
  end

  # enqueues the job object
  def enqueue_job
    Delayed::Backend::ActiveRecord::Job.enqueue self
  end
  
end
