require 'fileutils'
require 'builder'
class Content < ActiveRecord::Base
  
  belongs_to :issue
  belongs_to :location
  belongs_to :import_record
  
  has_many :images, as: :imageable, inverse_of: :imageable #, dependent: :destroy
  belongs_to :source, class_name: "Publication", foreign_key: "source_id"
  accepts_nested_attributes_for :images, allow_destroy: true
  attr_accessible :images_attributes

  attr_accessible :title, :subtitle, :authors, :content, :issue_id, :location_id, :copyright
  attr_accessible :guid, :pubdate, :categories, :topics, :summary, :url, :origin, :mimetype
  attr_accessible :language, :page, :wordcount, :authoremail, :source_id, :file
  attr_accessible :quarantine, :doctype, :timestamp, :contentsource, :source_content_id
  attr_accessible :image
  
  #before_save :inherit_issue_location
  
  default_scope :include => :issue, :order => "issues.publication_date DESC, contents.created_at DESC"

  # check if it should be marked quarantined
  before_save :mark_quarantined
  before_save :set_guid

  NEW_FORMAT = "New"
  KIM_FORMAT = "KIM"
  EXPORT_FORMATS = [KIM_FORMAT, NEW_FORMAT]
  DEFAULT_FORMAT = NEW_FORMAT

  PUBDATE_OUTPUT_FORMAT = "%Y-%m-%dT%H:%M:%S"

  rails_admin do
    list do
      filters [:source, :issue, :title, :authors, :import_record]
      items_per_page 100
      sort_by :pubdate, :source
      field :import_record
      field :location
      field :pubdate
      field :source
      field :issue
      field :title
      field :authors
    end
  end
  
  # sets content location to issue location if it was left blank
  def inherit_issue_location
    if self.location.nil?
      self.location = self.issue.location
    end
  end

  # creating a new content from import job data
  # is not as simple as just creating new from hash
  # because we need to match locations, publications, etc.
  def self.create_from_import_job(data, job=nil)
    # pull special attributes out of the data hash
    special_attrs = {}
    ['location', 'source', 'source', 'edition'].each do |key|
      if data.has_key? key and data[key].present?
        special_attrs[key] = data[key]
        data.delete key
      end
    end
    data.keys.each do |k|
      unless Content.accessible_attributes.entries.include? k
        log = Logger.new("#{Rails.root}/log/contents.log")
        log.debug("unknown key provided by parser: #{k}")
        data.delete k
      end
    end
    content = Content.new(data)
    # pull complex key/values out from data to use later
    if special_attrs.has_key? 'location'
      location = special_attrs['location']
      content.location = Location.where("city LIKE ?", "%#{location}%").first
      content.location = Location.new(city: location) if content.location.nil?
    end
    if special_attrs.has_key? "source"
      source = special_attrs["source"]
      content.source = Publication.where("name LIKE ?", "%#{source}%").first
      content.source = Publication.create(name: source) if content.source.nil?
    end
    if special_attrs.has_key? "edition"
      edition = special_attrs["edition"]
      content.issue = Issue.where("issue_edition LIKE ?", "%#{edition}%").where(publication_id: content.source_id, publication_date: content.pubdate).first
      # if not found, create a new one
      if content.issue.nil?
        content.issue = Issue.new(issue_edition: edition, publication_date: content.pubdate)
        content.issue.publication = content.source if content.source.present?
      end
    end
    content.import_record = job.last_import_record if job.present?

    # deal with existing content that needs to be overwritten
    # starting with matching publication AND source_content_id
    # but need to add (our) guid matching as well
    #
    # there's also an argument for having this above, and updating the record
    # instead of deleting the old one and creating a new one. not sure.
    if content.source.present? and content.source_content_id.present?
      Content.where(source_id: content.source.id, source_content_id: content.source_content_id).first.try(:destroy)
    end

    content.save!
    content
  end

  # check that doc validates our xml requirements
  # if not, mark it as quarantined
  def mark_quarantined
    unless title.present? and source.present? and pubdate.present?
      self.quarantine = true
    end
  end

  # if guid is empty, set with our own 
  def set_guid
    unless guid.present?
      self.guid = ""
      if title.present?
        self.guid << title.gsub(" ", "_").gsub("/", "-")
      else
        self.guid << "#{rand(10000)}-#{rand(10000)}"
      end
      self.guid << "-" << pubdate.strftime("%Y-%m-%d") if pubdate.present?
    end
  end

  def export_to_xml(format=nil)
    unless EXPORT_FORMATS.include? format
      format = DEFAULT_FORMAT
    end
    if quarantine == true
      return false
    else
      FileUtils.mkpath(export_path)
      File.open("#{export_path}/#{guid}.xml", "w+") do |f|
        if format == KIM_FORMAT
          f.write to_kim_xml
        else
          f.write to_new_xml
        end
      end
      File.open("#{export_path}/#{guid}.html", "w+") do |f|
        f.write content
      end
    end
  end

  # outputs a string of KIM formatted XML
  def to_kim_xml
    xml = ::Builder::XmlMarkup.new
    xml.instruct!
    xml.features do |f|
      attributes.each do |k,v|
        # ignore all the associations
        if /[[:alpha:]]*_id/.match(k).nil?
          if k == "pubdate" or k == "timestamp" and v.present?
            f.tag!(k, v.strftime(PUBDATE_OUTPUT_FORMAT))
          else
            f.tag!(k, v)
          end
        end
      end
      f.tag!("issue", issue.issue_edition) if issue.present?
      f.tag!("publication", source.name) if source.present?
      f.tag!("location", location.city) if location.present?
    end
    xml.target!
  end

  def to_new_xml
    xml = ::Builder::XmlMarkup.new
    xml.instruct!
    xml.tag!("tns:document", "xmlns:tns"=>"http://www.ontotext.com/DocumentSchema", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance") do |f|
      f.tag!("tns:feature-set") do |g|
        attributes.each do |k, v|
          g.tag!("tns:feature") do |h|
            if ["issue_id", "source_id", "location_id"].include? k
              if k == "issue_id" and issue.present?
                key, value = "issue", issue.issue_edition
              elsif k == "source_id" and source.present?
                key, value = "publication", source.name
              elsif k == "location_id" and location.present?
                key, value = "location", location.city
              end
            else
              key = k
              if key == "pubdate" or key == "timestamp" and v.present?
                value = v.strftime(PUBDATE_OUTPUT_FORMAT)
              else
                value = v
              end
            end
            unless key == "content"
              h.tag!("tns:name", key, "type"=>"xs:string")
              if key == "pubdate" or key == "timestamp"
                type = "xs:datetime"
              else
                type = "xs:string"
              end
              g.tag!("tns:value", value, "type"=>type)
            end
          end
        end
      end
      
      f.tag!("tns:document-parts") do |g|
        g.tag!("tns:document-part", "part"=>"BODY", "id"=>"1") do |h|
          h.tag!("tns:content", content)
        end
      end
      
    end
    xml.target!
  end
    

  # construct export path
  def export_path
    path = "#{Figaro.env.content_export_path}/#{source.name.gsub(" ", "_")}/#{pubdate.strftime("%Y")}/#{pubdate.strftime("%m")}/#{pubdate.strftime("%d")}"
  end

  
end
