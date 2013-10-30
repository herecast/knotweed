require 'find'
require 'yaml'
require 'json'
require "builder"
require 'fileutils'
require 'uri'

class ImportJob < ActiveRecord::Base

  belongs_to :organization
  belongs_to :parser
  
  validates_presence_of :organization
  
  attr_accessible :config, :last_run_at, :name, :parser_id, :source_path, :type, :organization_id
  
  validates :status, inclusion: { in: %w(failed running success queued), allow_nil: true }
  validate :parser_belongs_to_same_organization, unless: "parser.nil?"
  
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
    self.last_run_at = Time.now
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
          json = run_parser(path) || nil
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
    data.each do |article|
      begin
        Content.create_from_import_job(article)
      rescue StandardError => bang
        log = Logger.new("#{Rails.root}/log/contents.log")
        log.debug("failed to process content: #{bang}")
      end
    end
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

  private

  def parser_belongs_to_same_organization
    if parser.organization and organization_id != parser.organization.id
      errors.add(:parser_id, 'parser must belong to the same organization')
    end
  end
      

end
