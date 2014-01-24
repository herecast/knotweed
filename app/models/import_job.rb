require 'find'
require 'json'
require "builder"
require 'fileutils'
require 'uri'
require 'jobs/scheduledjob'

class ImportJob < ActiveRecord::Base

  include Jobs::ScheduledJob
  QUEUE = "imports"

  belongs_to :organization
  belongs_to :parser
  belongs_to :content_set
  has_many :import_records
  
  validates_presence_of :organization
  
  attr_accessible :config, :name, :parser_id, :source_path, :type, 
                  :organization_id, :frequency, :archive, :content_set_id
  
  validates :status, inclusion: { in: %w(failed running success queued) }, allow_nil: true
  validate :parser_belongs_to_same_organization, unless: "parser.nil?"

  after_destroy :cancel_scheduled_runs

  default_scope { where archive: false }

  serialize :config, Hash

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
    update_attribute(:status, "queued")
  end
  
  def success(job)
    update_attribute(:status, "success")
  end

  def error(job, exception)
    log = last_import_record.log_file
    log.info "input: #{self.source_path}"
    log.info "parser: #{Figaro.env.parsers_path}/#{parser.filename}"
    log.error "error: #{exception}"
    log.error "backtrace: #{exception.backtrace.join("\n")}"   
    update_attribute(:status, "failed")
    log.info "#{self.inspect}"
  end
  
  def failure(job)
    update_attribute(:status, "failed")
  end
  
  def before(job)
    update_attribute(:status, "running")
    # set last_run_at regardless of success or failure
    import_records.create
  end

  # enqueues the job object
  # note can use option run_at: time to schedule in the future
  def enqueue_job
    Delayed::Job.enqueue self, queue: QUEUE
  end
  
  def traverse_input_tree
    # check if source_path is a url -- if it is
    # this is an rss feeder and we should
    # just pass the source_path directly to
    # the parser
    log = last_import_record.log_file
    log.info("#{Time.now}")
    log.info("source path: #{source_path}")
    if source_path =~ /^#{URI::regexp}$/
      data = run_parser(source_path) || nil
      docs_to_contents(data) if data.present?
    else
      Find.find(source_path) do |path|
        if FileTest.directory?(path)
          next
        else
          log.debug("running parser on path: #{path}")
          begin
            data = run_parser(path)
          rescue StandardError => bang
            log.error("failed to parse #{path}: #{bang}")
            data = nil
          end
          docs_to_contents(data) if data.present?
        end
      end
    end
  end
     
  # runs the parser's parse_file method on a file located at path
  # outputs a json array of articles (if parser is correct)
  # 
  def run_parser(path)
    require "#{Figaro.env.parsers_path}/#{parser.filename}"
    return parse_file(path, config)
  end

  # accepts json array of articles
  # and creates content entries for them
  def docs_to_contents(docs)
    if docs.is_a? String
      data = JSON.parse docs
    else # it's already a hash and we don't need to decode from JSON
      data = docs
    end
    import_record = last_import_record
    successes = 0
    failures = 0
    log = import_record.log_file
    data.each do |article|
      # trim all fields so we don't get any unnecessary whitespace
      article.each_value { |v| v = v.strip if v.is_a? String }
      # remove leading empty <p> tags from content
      if article.has_key? "content" and article["content"].present?
        p_tags_match = article["content"].match(/\A(<p>|<\/p>| )+/)
        if p_tags_match
          content_start = p_tags_match[0].length - 1
          article["content"].slice!(0..content_start)
        end
      end
        
      begin
        c = Content.create_from_import_job(article, self)
        log.info("content #{c.id} created")
        successes += 1
      rescue StandardError => bang
        log.error("failed to process content: #{bang}")
        failures += 1
      end
    end
    log.info("successes: #{successes}")
    log.info("failures: #{failures}")
    import_record.items_imported += successes
    import_record.failures += failures
    import_record.save!
  end

  def save_config(parameters)
    self.update_attribute(:config, parameters)
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
