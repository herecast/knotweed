require 'find'
require 'yaml'
require 'json'
require "builder"

class ImportJob < ActiveRecord::Base

  belongs_to :organization
  belongs_to :parser
  
  validates_presence_of :organization
  
  attr_accessible :config, :last_run_at, :name, :parser_id, :source_path, :type, :organization_id
  
  validates :status, inclusion: { in: %w(failed running success queued), allow_nil: true }
  
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
    log.debug "output: #{Figaro.env.import_job_output_path}"
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
    job_folder_label = self.job_output_folder
    Dir.mkdir("#{Figaro.env.import_job_output_path}/#{job_folder_label}") unless Dir.exists?("#{Figaro.env.import_job_output_path}/#{job_folder_label}")
    Find.find(source_path) do |path|
      if FileTest.directory?(path)
        next
      else
        json = run_parser(path) || nil
        if json.present?
          json_to_corpus(json, File.basename(path, ".*"))
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
      
  # accepts a json array of articles
  # and a basename (folder name) for the output
  # outputs a folder structure to the corpus path
  def json_to_corpus(json, output_basename)
    data = JSON.parse json
    data.each do |article|
      xml = ::Builder::XmlMarkup.new
      xml.instruct!
      xml.features do |f|
        article.keys.each do |k|
          eval("f.#{k} article[k]")
        end
      end
      xml_out = xml.target!
    
      txt_out = ""
      # quick way to generate txt template
      ["title", "subtitle", "author", "contentsource", "content", "correctiondate", "correction", "timestamp"].each do |feature|
        unless article[feature].nil? or article[feature].empty?
          # this adds an extra line below the content
          txt_out << "\n" if feature == "content"
          if feature == "correctiondate"
            txt_out << "\n" << "Correction Date: "
          elsif feature == "correction"
            txt_out << "Correction: "
          end
          txt_out << article[feature] << "\n"
        end
      end
    
      # directory structure of output
      job_folder_label = job_output_folder
      base_path = "#{Figaro.env.import_job_output_path}/#{job_folder_label}/#{output_basename}"
      Dir.mkdir(base_path) unless Dir.exists?(base_path)
      month = article["timestamp"][5..6]
      Dir.mkdir(base_path + "/#{month}") unless Dir.exists?(base_path + "/#{month}")
      filename = article["guid"].gsub("/", "-").gsub(" ", "_")

      File.open("#{base_path}/#{month}/#{filename}.xml", "w+:UTF-8") do |f|
        f.write xml_out
      end
      File.open("#{base_path}/#{month}/#{filename}.txt", "w+:UTF-8") do |f|
        f.write txt_out
      end
    end
  end

  # helper method for defining job-run-specific output folder
  # (formatting of timestamp)
  def job_output_folder
    if last_run_at
      last_run_at.strftime("%Y%m%d%H%M%S") 
    else
      nil
    end
  end

end
