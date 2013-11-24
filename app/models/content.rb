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
  attr_accessible :image, :published
  

  # check if it should be marked quarantined
  before_save :mark_quarantined
  before_save :set_guid

  NEW_FORMAT = "New"
  KIM_FORMAT = "KIM"
  EXPORT_FORMATS = [KIM_FORMAT, NEW_FORMAT]
  DEFAULT_FORMAT = NEW_FORMAT

  PUBDATE_OUTPUT_FORMAT = "%Y-%m-%dT%H:%M:%S"

  BASE_URI = "http://www.subtext.org/Document"

  rails_admin do
    list do
      filters [:source, :issue, :title, :authors, :import_record, :location]
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
    # if job is passed in, set organization
    if job
      organization = job.try(:organization)
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
      if organization
        content.source = Publication.where("organization_id = ? OR organization_id IS NULL", organization.id).where("name LIKE ?", "%#{source}%").first
      else
        content.source = Publication.where("name LIKE ?", "%#{source}%").first
      end
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

    content.set_guid # otherwise it won't be set till save and we need it for overwriting

    # deal with existing content that needs to be overwritten
    # starting with matching publication AND source_content_id
    # but need to add (our) guid matching as well
    #
    # logic here is: IF source exists and source_content_id exists, overwrite based on matching those two
    # ELSIF: overwrite based on matching guid
    # ELSE: don't overwrite, create a new one
    #
    # TODO: this should probably be factored out into a before_save filter
    if content.source.present? and content.source_content_id.present?
      existing_content = Content.where(source_id: content.source.id, source_content_id: content.source_content_id).try(:first)
    end
    if existing_content.nil? and content.source.present?
      existing_content = Content.where(source_id: content.source.id, guid: content.guid).try(:first)
    end
    if existing_content.present?
      content.id = existing_content.id
      existing_content.destroy
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
      self.guid = CGI::escape guid
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
  
  # function to post to Ontotext's prototype
  # using the "new" xml format
  def post_to_ontotext
    options = { :body => self.to_new_xml, :timeout => 10*60 }
    
    response = Admin::OntotextController.post('/prototype/processDocument?persist=true', options)
    if response.body.include? "#{BASE_URI}/#{id}"
      self.published = true
      self.save
      return true
    else
      log = Logger.new("#{Rails.root}/log/publishing.log")
      log.debug("failed to post doc #{self.id}")
      return false
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
    xml.tag!("tns:document", "xmlns:tns"=>"http://www.ontotext.com/DocumentSchema", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "id" => "#{BASE_URI}/#{id}") do |f|

      f.tag!("tns:document-parts") do |g|
        f.tag!("tns:feature-set") do |g|
          attributes.each do |k, v|
            if ["id", "created_at", "updated_at", "quarantine", "import_record_id", "published"].include? k
              next
            end
            g.tag!("tns:feature") do |h|
              if ["issue_id", "source_id", "location_id"].include? k
                if k == "issue_id" and issue.present?
                  key, value = "ISSUE", issue.issue_edition
                elsif k == "source_id" and source.present?
                  key, value = "SOURCE", source.name
                elsif k == "location_id" and location.present?
                  key, value = "LOCATION", location.city
                end
              else
                key = k.upcase
                if key == "PUBDATE" or key == "TIMESTAMP" and v.present?
                  value = v.strftime(PUBDATE_OUTPUT_FORMAT)
                else
                  value = v
                end
              end
              unless key == "CONTENT"
                h.tag!("tns:name", key, "type"=>"xs:string")
                g.tag!("tns:value", value, "type"=>"xs:string")
              end
            end
          end
        end
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

  # method that constructs an active relation
  # of contents based on a query hash of conditions
  # expects query_params to look like the params hash from a form
  def self.contents_query(query_params)
    query = {
      quarantine: false, # can't publish quarantined docs
      published: false # default to not yet published
    }
    if query_params[:source_id].present?
      query[:source_id] = query_params[:source_id].map { |s| s.to_i } 
    end
    if query_params[:location_id].present?
      query[:location_id] = query_params[:location_id].map { |s| s.to_i } 
    end
    if query_params[:published] == "true"
      query[:published] = true
    elsif query_params[:published] == "both"
      query.delete(:published)
    end
    contents = Content.where(query)
    contents = contents.where("pubdate >= ?", Date.parse(query_params[:from])) if query_params[:from].present?
    contents = contents.where("pubdate <= ?", Date.parse(query_params[:to])) if query_params[:to].present?
    return contents
  end
    
end
