# == Schema Information
#
# Table name: import_jobs
#
#  id                    :integer          not null, primary key
#  parser_id             :integer
#  name                  :string(255)
#  config                :text
#  source_path           :string(255)
#  job_type              :string(255)
#  organization_id       :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  status                :string(255)
#  frequency             :integer          default(0)
#  archive               :boolean          default(FALSE), not null
#  content_set_id        :integer
#  run_at                :datetime
#  stop_loop             :boolean          default(TRUE)
#  automatically_publish :boolean          default(FALSE)
#  repository_id         :integer
#  publish_method        :string(255)
#

require 'find'
require 'json'
require "builder"
require 'fileutils'
require 'uri'
require 'jobs/scheduledjob'

class ImportJob < ActiveRecord::Base

  include Jobs::ScheduledJob
  QUEUE = "imports"
  PARSER_PATH = "#{Rails.root}/lib/parsers"

  belongs_to :organization
  belongs_to :parser
  belongs_to :content_set
  belongs_to :repository
  has_many :import_records

  has_many :notifiers, as: :notifyable
  has_many :notifyees, through: :notifiers, class_name: "User", source: "user"
  
  validates_presence_of :organization
  
  attr_accessible :config, :name, :parser_id, :source_path, :job_type, 
                  :organization_id, :frequency, :archive, :content_set_id,
                  :run_at, :stop_loop, :automatically_publish, :repository_id,
                  :publish_method, :job_type
  
  validates :status, inclusion: { in: %w(failed running success scheduled) }, allow_nil: true
  validate :parser_belongs_to_same_organization, unless: "parser.nil?"

  after_destroy :cancel_scheduled_runs

  default_scope { where archive: false }

  serialize :config, Hash

  CONTINUOUS = "continuous"
  AD_HOC = "ad_hoc"
  RECURRING = "recurring"
  JOB_TYPES = [CONTINUOUS, AD_HOC, RECURRING]

  before_validation :set_stop_loop

  # if job type is continuous, save stop_loop as false
  # otherwise, save it to true so non-continuous jobs don't loop
  def set_stop_loop
    if job_type == CONTINUOUS
      self.stop_loop = false
    else
      self.stop_loop = true
    end
    true
  end

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
  
  # if config var RESCHEDULE_AT is set (to a number of seconds),
  # override delayed_job reschedule_at and schedule next attempt
  # using config var.
  # if not set, default to standard delayed_job behavior
  def reschedule_at(current_time, attempts)
    if Figaro.env.respond_to? :reschedule_at
      current_time + Figaro.env.reschedule_at.to_i.seconds
    else # default delayed_job behavior
      current_time + attempts**4 + 5
    end
  end

  # hooks to set status
  def enqueue(job)
    update_attribute(:status, "scheduled")
  end
  
  def success(job)
    update_attribute(:status, "success")
  end

  def error(job, exception)
    log = last_import_record.log_file
    log.info "input: #{self.source_path}"
    log.info "parser: #{PARSER_PATH}/#{parser.filename}"
    log.error "error: #{exception}"
    if notifyees.present?
      JobMailer.error_email(last_import_record, exception).deliver
    end
    log.error "backtrace: #{exception.backtrace.join("\n")}"   
    update_attribute(:status, "failed")
    log.info "#{self.inspect}"
  end
  
  def before(job)
    update_attribute(:status, "running")
    # set last_run_at regardless of success or failure
    import_records.create
  end

  # enqueues the job object
  # note can use option run_at: time to schedule in the future
  def enqueue_job(specific_time=nil)
    Delayed::Job.enqueue self, queue: QUEUE, run_at: (specific_time || run_at)
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
      # this is where we loop continuous jobs
      # continuous jobs are automatically set to have stop_loop set to false
      # other jobs have stop_loop set to true (by an after_create callback).
      while true
        log.info("Running parser at #{Time.now}")
        data = run_parser(source_path) || nil
        if data.present?
          docs_to_contents(data)
        else
          # sleep for a bit if there is no new contents to import and we're supposed to keep looping
          sleep(5.0) unless self.stop_loop
        end
        # hacky trick to stop continuous jobs during backup time
        if Time.now > Chronic.parse("6:45 am") and Time.now < Chronic.parse("7:45 am")
          # then update stop_loop attribute to break out of the cycle
          update_attribute :stop_loop, true
          # first, schedule the job to run again at 7:45 am.
          enqueue_job(Chronic.parse("8:00 am"))
        end
        self.reload
        break if self.stop_loop
      end
      # if it was a continuous job that was manually stopped using the stop_loop flag
      # we need to reset the flag to false
      if self.stop_loop and job_type == CONTINUOUS
        update_attribute :stop_loop, false
      end
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
    require "#{PARSER_PATH}/#{parser.filename}"
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
      article.each_value { |v| v.strip! if v.is_a? String and v.frozen? == false }
      # remove leading empty <p> tags from content
      if article.has_key? "content"
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
        if automatically_publish and repository.present?
          c.publish(publish_method, repository)
        end
      rescue StandardError => bang
        log.error("failed to process content: #{bang}")
        failures += 1
      end
    end
    log.info("successes: #{successes}")
    log.info("failures: #{failures}")
    import_record.items_imported += successes
    import_record.failures += failures
    import_record.save
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
