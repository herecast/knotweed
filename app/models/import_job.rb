require 'find'
require 'yaml'
require 'json'
require "builder"
require 'fileutils'
require 'uri'
require 'lib/scheduledjob.rb'

class ImportJob < ActiveRecord::Base

  include Jobs::ScheduledJob

  belongs_to :organization
  belongs_to :parser
  has_many :import_records
  
  validates_presence_of :organization
  
  attr_accessible :config, :name, :parser_id, :source_path, :type, :organization_id, :frequency
  
  validates :status, inclusion: { in: %w(failed running success queued), allow_nil: true }
  validate :parser_belongs_to_same_organization, unless: "parser.nil?"

  after_destroy :cancel_scheduled_runs

  # delayed job action
  # 
  # determines the process needed to run the import job (parser, scraping, etc.)
  # and activates it
  def perform
    # for now this is always true...but as we introduce import jobs via scrape, etc., it may change.
    # we can include the logic for selecting what branch to descend (scrape, parse, etc.) here as it 
    # is defined
    if parser.present?
      traverse_input_tree
    end
  end
  
  # hooks to set status
  def enqueue(job)
    self.status = "queued"
    self.save
  end
  
  def success(job)
    self.status = "success"
    self.save
  end

  def error(job, exception)
    log = Logger.new("#{Rails.root}/log/delayed_job.log")
    log.debug "input: #{self.source_path}"
    log.debug "parser: #{Figaro.env.parsers_path}/#{parser.filename}"
    log.debug "error: #{exception}"
    log.debug "backtrace: #{exception.backtrace.join("\n")}"   
    self.status = "failed"
    log.debug self
    self.save
  end
  
  def failure(job)
    self.status = "failed"
    self.save
  end
  
  def before(job)
    self.status = "running"
    # set last_run_at regardless of success or failure
    self.import_records.create
    self.save
  end
  


  # enqueues the job object
  # note can use option run_at: time to schedule in the future
  def enqueue_job
    Delayed::Job.enqueue self
  end
  
  def traverse_input_tree
    # check if source_path is a url -- if it is
    # this is an rss feeder and we should
    # just pass the source_path directly to
    # the parser
    log = Logger.new("#{Rails.root}/log/import_job.log")
    log.debug("source path: #{source_path}")
    if source_path =~ /^#{URI::regexp}$/
      json = run_parser(source_path) || nil
      #json_to_corpus(json, File.basename(source_path, ".*")) if json.present?
      json_to_contents(json) if json.present?
    else
      Find.find(source_path) do |path|
        if FileTest.directory?(path)
          next
        else
          log.debug("running parser on path: #{path}")
          begin
            json = run_parser(path)
          rescue StandardError => bang
            log.debug("failed to parse #{path}: #{bang}")
            json = nil
          end

          #json_to_corpus(json, File.basename(path, ".*")) if json.present?
          json_to_contents(json) if json.present?
        end
      end
    end
  end
     
  # runs the parser's parse_file method on a file located at path
  # outputs a json array of articles (if parser is correct)
  def run_parser(path)
    require "#{Figaro.env.parsers_path}/#{parser.filename}"
    # get config from the import_job and convert to hash
    if self.config.present?
      conf = YAML.load(self.config) || {}
    else
      conf = {}
    end
    return parse_file(path, conf)
  end

  # accepts json array of articles
  # and creates content entries for them
  def json_to_contents(json)
    data = JSON.parse json
    import_record = self.last_import_record
    successes = 0
    failures = 0
    data.each do |article|
      begin
        Content.create_from_import_job(article, self)
        successes += 1
      rescue StandardError => bang
        log = Logger.new("#{Rails.root}/log/contents.log")
        log.debug("failed to process content: #{bang}")
        failures += 1
      end
    end
    import_record.items_imported += successes
    import_record.failures += failures
    import_record.save!
  end

  def save_config(parameters)
    if parameters.present?
      conf = {}
      parameters.each do |key, val|
        conf[key] = val
      end
      self.config = conf.to_yaml
      self.save
    end
  end

  # gets next scheduled run
  # returns nil if not scheduled to run
  def next_scheduled_run
    job = Delayed::Job.where("handler LIKE '%ImportJob%' AND handler LIKE '% id: ?%'", id).order("run_at ASC").first
    job ? job.run_at : nil
  end

  # cancel scheduled runs by removing any Delayed::Job
  # records pointing to this job
  def cancel_scheduled_runs
    Delayed::Job.where("handler LIKE '%ImportJob%' AND handler LIKE '% id: ?%'", id).delete_all
  end

  # returns the most recent import record
  def last_import_record
    import_records.order("created_at DESC").first
  end

  # returns time last run at
  def last_run_at
    last_import_record.try(:created_at)
  end

  private

  def parser_belongs_to_same_organization
    if parser.organization and organization_id != parser.organization.id
      errors.add(:parser_id, 'parser must belong to the same organization')
    end
  end
      

end
