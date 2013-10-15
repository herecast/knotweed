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
    # check if source_path is a url -- if it is
    # this is an rss feeder and we should
    # just pass the source_path directly to
    # the parser
    log = Logger.new("#{Rails.root}/log/import_job.log")
    log.debug("source path: #{source_path}")
    if source_path =~ /^#{URI::regexp}$/
      json = run_parser(source_path) || nil
      json_to_corpus(json, File.basename(source_path, ".*")) if json.present?
    else
      Find.find(source_path) do |path|
        if FileTest.directory?(path)
          next
        else
          log.debug("running parser on path: #{path}")
          json = run_parser(path) || nil
          json_to_corpus(json, File.basename(path, ".*")) if json.present?
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

      base_path = "#{Figaro.env.import_job_output_path}/#{job_output_folder}/#{output_basename}"
      
      # validate that article meets the basic format requirements
      # for the corpus, if not, output to quarantine folder
      unless validate_doc(article)
        log = Logger.new("#{Rails.root}/log/import_job.log")
        log.debug("document #{article['guid']} not valid")
        base_path = "/#{Figaro.env.import_job_output_path}/#{job_output_folder}/quarantine/#{output_basename}"
      end

      xml = ::Builder::XmlMarkup.new
      xml.instruct!
      xml.tag!("tns:document", "xmlns:tns"=>"http://www.ontotext.com/DocumentSchema", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance") do |f|
        f.tag!("tns:feature-set") do |g|
          article.each do |k, v|
            g.tag!("tns:feature") do |h|
              h.tag!("tns:name", k, "type"=>"xs:string")
              unless k == "content" or k == "title"
                if k == "pubdate" or k == "timestamp"
                  type = "xs:datetime"
                else
                  type = "xs:string"
                end
                g.tag!("tns:value", article[k], "type"=>type)
              end
            end
          end
        end
        
        f.tag!("tns:document-parts") do |g|
          g.tag!("tns:document-part", "part"=>"TITLE", "id"=>"1") do |h|
            h.tag!("tns:content", article["title"])
          end
          g.tag!("tns:document-part", "part"=>"BODY", "id"=>"2") do |h|
            h.tag!("tns:content", article["content"])
          end
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
      month = article["timestamp"][5..6] if article.has_key? "timestamp" and article["timestamp"].present?
      # ensure we can still write to a directory if month is somehow empty (for non-validating entries)
      month = "no-month" unless month.present?
      FileUtils.mkdir_p(base_path + "/#{month}")
      if article.has_key? "guid" and article["guid"].present?
        filename = article["guid"].gsub("/", "-").gsub(" ", "_")
      else
        # try to come up with something unique enough
        filename = "#{rand(10000)-rand(10000)}"
      end

      File.open("#{base_path}/#{month}/#{filename}.xml", "w+:UTF-8") do |f|
        f.write xml_out
      end
      File.open("#{base_path}/#{month}/#{filename}.txt", "w+:UTF-8") do |f|
        f.write txt_out
      end
    end
  end

  # method to validate incoming documents before sending them to the corpus
  def validate_doc(doc)
    # check that the required keys exist
    unless doc.has_key? "pubdate" and doc.has_key? "timestamp" and doc.has_key? "title" and doc.has_key? "source"
      return false
    end
    # validate pubdate and timestamp format
    [doc["pubdate"], doc["timestamp"]].each do |date|
      if /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.match(date).nil?
        return false
      end
    end
    # validate source and title are present?
    [doc["source"], doc["title"]].each do |feature|
      return false unless feature.present?
    end
    return true
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
