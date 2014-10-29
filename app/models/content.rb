# encoding: utf-8
# == Schema Information
#
# Table name: contents
#
#  id                   :integer          not null, primary key
#  title                :string(255)
#  subtitle             :string(255)
#  authors              :string(255)
#  raw_content          :text
#  issue_id             :integer
#  import_location_id   :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  copyright            :string(255)
#  guid                 :string(255)
#  pubdate              :datetime
#  source_category      :string(255)
#  topics               :string(255)
#  summary              :text
#  url                  :string(255)
#  origin               :string(255)
#  mimetype             :string(255)
#  language             :string(255)
#  page                 :string(255)
#  wordcount            :string(255)
#  authoremail          :string(255)
#  source_id            :integer
#  file                 :string(255)
#  quarantine           :boolean          default(FALSE)
#  doctype              :string(255)
#  timestamp            :datetime
#  contentsource        :string(255)
#  import_record_id     :integer
#  source_content_id    :string(255)
#  parent_id            :integer
#  event_type           :string(255)
#  start_date           :datetime
#  end_date             :datetime
#  cost                 :string(255)
#  recurrence           :string(255)
#  links                :text
#  host_organization    :string(255)
#  business_location_id :integer
#  featured             :boolean          default(FALSE)
#  content_category_id  :integer
#  category_reviewed    :boolean          default(FALSE)
#  processed_content    :text
#

require 'fileutils'
require 'builder'
include ActionView::Helpers::TextHelper
class Content < ActiveRecord::Base

  belongs_to :issue
  belongs_to :import_location
  belongs_to :import_record

  belongs_to :business_location # for event type contents
  accepts_nested_attributes_for :business_location,
    reject_if: proc { |attributes| attributes['name'].blank? and attributes['address'].blank? }
  attr_accessible :business_location_attributes, :business_location_id

  has_many :annotation_reports
  has_many :category_corrections

  has_and_belongs_to_many :publish_records
  has_and_belongs_to_many :repositories, :uniq => true
  
  has_many :images, as: :imageable, inverse_of: :imageable, dependent: :destroy
  belongs_to :source, class_name: "Publication", foreign_key: "source_id"
  accepts_nested_attributes_for :images, allow_destroy: true
  attr_accessible :images_attributes

  belongs_to :parent, class_name: "Content"
  has_many :children, class_name: "Content", foreign_key: "parent_id"

  has_many :promotions

  belongs_to :content_category

  attr_accessible :title, :subtitle, :authors, :issue_id, :import_location_id, :copyright,
                  :guid, :pubdate, :source_category, :topics, :summary, :url, :origin, :mimetype,
                  :language, :page, :wordcount, :authoremail, :source_id, :file,
                  :quarantine, :doctype, :timestamp, :contentsource, :source_content_id,
                  :image_ids, :parent_id, :source_uri, :category,
                  :event_type, :start_date, :end_date, :cost, :recurrence, :host_organization,
                  :links, :featured, :content_category_id, :category_reviewed, :raw_content, :processed_content,
                  :sanitized_content

  serialize :links, Hash

  # check if it should be marked quarantined
  before_save :mark_quarantined
  before_save :set_guid

  scope :events, -> { joins(:content_category).where("content_categories.name = ? or content_categories.name = ?",
                                                     "event", "sale_event") }

  def initialize args = {}
    if not args.nil? and args[:category].present? 
      cat = ContentCategory.find_or_create_by_name(args.delete :category) 
      send("content_category=", cat)
    end
    super
  end

  NEW_FORMAT = "New"
  EXPORT_FORMATS = [NEW_FORMAT]
  DEFAULT_FORMAT = NEW_FORMAT

  PUBDATE_OUTPUT_FORMAT = "%Y-%m-%dT%H:%M:%S"

  BASE_URI = "http://www.subtext.org/Document"

  DEFAULT_PUBLISH_METHOD = "export_to_xml"

  # publish methods are string representations
  # of methods on the Content model
  # that are called via send on each piece of content
  POST_TO_ONTOTEXT = "post_to_ontotext"
  EXPORT_TO_XML = "export_to_xml"
  REPROCESS = "reannotate_at_ontotext"
  EXPORT_PRE_PIPELINE = "export_pre_pipeline_xml"
  EXPORT_POST_PIPELINE = "export_post_pipeline_xml"
  PUBLISH_METHODS = [POST_TO_ONTOTEXT, EXPORT_TO_XML, REPROCESS, EXPORT_PRE_PIPELINE, EXPORT_POST_PIPELINE]

  # features that can be overwritten when we reimport
  REIMPORT_FEATURES = %w(title subtitle authors raw_content pubdate source_category topics summary
                         url authoremail import_record)

  CATEGORIES = %w(beta_talk business campaign discussion event for_free lifestyle 
                  local_news nation_world offered presentation recommendation
                  sale_event sports wanted)

  BLACKLIST_BLOCKS = File.readlines(Rails.root.join('lib', 'content_blacklist.txt')) 

   # display processed content if available
  # otherwise, raw content
  def content
    if processed_content.present?
      processed_content
    else
      raw_content
    end
  end

  # if passed a repo, checks if this content was published in that repo
  # otherwise, checks if it is published in any repo
  def published?(repo=nil)
    if repo.present?
      repo.include? self
    else
      repositories.present?
    end
  end

  def document_uri
    "#{BASE_URI}/#{id}"
  end

  def source_uri
    "<http://www.subtext.org/#{source.class.to_s}/#{source.id}>"
  end

  def parent_uri
    "#{BASE_URI}/#{parent_id}" unless parent_id.nil?
  end

  def source_name
    source.name
  end

  def location
    unless import_location.nil?
      import_location.city if import_location.status == ImportLocation::STATUS_GOOD
    end
  end

  def category
    return content_category.name unless content_category.nil?
  end

  # return parent category name if it exists
  def parent_category
    return self.try(:content_category).try(:parent).try(:name)
  end


  def category= new_cat
    cat = ContentCategory.find_or_create_by_name new_cat unless new_cat.nil?
    self.content_category = cat 
  end
  
  # creating a new content from import job data
  # is not as simple as just creating new from hash
  # because we need to match locations, publications, etc.
  def self.create_from_import_job(input, job=nil)
    if job
      log = job.last_import_record.log_file
    else
      log = Logger.new("#{Rails.root}/log/contents.log")
    end
    # pull special attributes out of the data hash
    special_attrs = {}
    # convert symbols to strings
    data = {}
    input.each do |k,v|
      if k.is_a? Symbol
        key = k.to_s
      else
        key = k
      end
      if ['image', 'location', 'source', 'edition', 'imagecaption', 'imagecredit', 'in_reply_to', 'categories'].include? key
        special_attrs[key] = v if v.present?
      elsif v.present?
        data[key] = v
      end
    end

    raw_content = data.delete 'content'

    data.keys.each do |k|
      unless Content.accessible_attributes.entries.include? k
        log.debug("unknown key provided by parser: #{k}")
        data.delete k
      end
    end

    # if job is passed in, set organization
    organization = job.try(:organization)

    content = Content.new(data)
    content.raw_content = raw_content
    
    # pull complex key/values out from data to use later
    if special_attrs.has_key? 'location'
      import_location = special_attrs['location']
      content.import_location = ImportLocation.find_or_create_from_match_string(import_location)
    end
    if special_attrs.has_key? "source"
      source = special_attrs["source"]
      if organization
        # try to match content name exactly
        pub = Publication.where("organization_id = ? OR organization_id IS NULL", organization.id).find_by_name(source)
        # if that doesn't work, try a "LIKE" query
        pub = Publication.where("organization_id = ? OR organization_id IS NULL", organization.id).where("name LIKE ?", "%#{source}%").first if pub.nil?
        # if that still doesn't work, create a new publication
        pub = Publication.create(name: source, organization_id: organization.id) if pub.nil?

        content.source = pub
      else
        content.source = Publication.where("name LIKE ?", "%#{source}%").first
        content.source = Publication.create(name: source) if content.source.nil?
      end
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
    if special_attrs.has_key? "categories"
      content.source_category = special_attrs['categories']
    end
    if special_attrs.has_key? "in_reply_to"
      content.parent = Content.find_by_guid(special_attrs["in_reply_to"])
    end
      
    content.import_record = job.last_import_record if job.present?

    content.set_guid unless content.guid.present? # otherwise it won't be set till save and we need it for overwriting

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
      # if existing content is there, rather than saving, we update
      # the whitelisted reimport attributes
      REIMPORT_FEATURES.each do |f|
        existing_content.send "#{f}=", content.send(f.to_sym) if content.send(f.to_sym).present?
      end
      content = existing_content
    end

    content.save!


    # if the content saves, add any images that came in
    # this has to be down here, not in the special_attributes CASE statement
    # because we don't want to create the images if the content doesn't save.
    if special_attrs.has_key? "image"
      # CarrierWave validation should take care of validating this for us
      image_attrs = {
        remote_image_url: special_attrs["image"],
        source_url: special_attrs["image"]
      }
      image_attrs[:caption] = special_attrs["imagecaption"] if special_attrs.has_key? "imagecaption"
      image_attrs[:credit] = special_attrs["imagecredit"] if special_attrs.has_key? "imagecredit"
      content.images.create(image_attrs)
    end

    content

  end

  # check that doc validates our xml requirements
  # if not, mark it as quarantined
  def mark_quarantined
    if title.present? and source.present? and pubdate.present? and raw_content.present?
      self.quarantine = false
    else
      self.quarantine = true
    end
    true
  end

  # if guid is empty, set with our own 
  def set_guid
    unless self.guid.present?
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

  # catchall publish method that handles interacting w/ the publish record
  def publish(method, repo, record=nil, opts={})
    if method.nil?
      method = DEFAULT_PUBLISH_METHOD
    end
    # if there is a publish record, log output to corresponding log file
    if record.present?
      log = record.log_file
      file_list = record.files
    else
      log = Logger.new("#{Rails.root}/log/publishing.log")
      if opts[:download_result].present?
        file_list = []
      end
    end
    result = false
    opts[:file_list] = file_list unless file_list.nil?
    begin
      result = self.send method.to_sym, repo, opts
      if result == true
        record.items_published += 1 if record.present?
      else
        log.error("Export of #{self.id} failed (returned: #{result})")
        record.failures += 1 if record.present?
      end
    rescue => e
      log.error("Error exporting #{self.id}: #{e}")
      record.failures += 1 if record.present?
    end
    record.save if record.present?
    if opts[:download_result].present? and not file_list.nil? and file_list.length > 0
      opts[:download_result] = file_list[0]
    end
    result
  end

  # below are our various "publish methods"
  # new publish methods should return true
  # if publishing is successful and a string
  # with an error message if it is not.

  def export_to_xml(repo, opts = {}, format=nil)
    file_list = opts[:file_list] || Array.new
    unless EXPORT_FORMATS.include? format
      format = DEFAULT_FORMAT
    end
    if quarantine == true
      return "doc #{id} is quarantined and was not exported"
    else
      FileUtils.mkpath(export_path)
      xml_path = "#{export_path}/#{guid}.xml"
      File.open(xml_path, "w+") do |f|
        f.write to_new_xml
      end
      File.open("#{export_path}/#{guid}.html", "w+") do |f|
        f.write sanitized_content
      end
      file_list << xml_path
      return true
    end
  end
  
  # function to post to Ontotext's prototype
  # using the "new" xml format
  def post_to_ontotext(repo, opts={})
    options = { :body => self.to_new_xml }
                
    response = OntotextController.post(repo.dsp_endpoint + '/processDocument?persist=true', options)
    if response.body.include? document_uri
      repo.contents << self unless repo.contents.include? self
      # trigger updating hasActivePromotion if publish succeeded
      if has_active_promotion?
        # we only need this run on one promotion, not all of them
        promotions.where(active: true).first.mark_active_promotion(repo)
      end

      # trigger feedback update from pipeline (updating DB with pipeline-processed fields)
      update_from_repo(repo)
      return true
    else
      return "failed to post doc: #{self.id}\nresponse:#{response.body}"
    end
  end

  def reannotate_at_ontotext(repo, opts = {})
    options = { :id => document_uri }
    response = OntotextController.post(repo.dsp_endpoint + '/reprocessDocument', options)
    if response.code != 200
      post_to_ontotext
    else
      return true
    end
  end

  def to_new_xml
    xml = ::Builder::XmlMarkup.new
    xml.instruct!
    xml.tag!("tns:document", "xmlns:tns"=>"http://www.ontotext.com/DocumentSchema", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "id" => document_uri) do |f|

      f.tag!("tns:document-parts") do |g|
        f.tag!("tns:feature-set") do |g|
          feature_set.each do |k, v|
            g.tag!("tns:feature") do |h|
              if ["issue_id", "source_id", "import_location_id", "parent_id"].include? k
                if k == "issue_id" and issue.present?
                  key, value = "ISSUE", issue.issue_edition
                elsif k == "source_id" and source.present?
                  key, value = "SOURCE", source.name
                elsif k == "import_location_id" and import_location.present?
                  if import_location.status == ImportLocation::STATUS_GOOD
                    key, value = "LOCATION", import_location.city
                  end
                elsif k == "parent_id" and parent.present?
                  key, value = "PARENT", "#{Figaro.env.document_prefix}#{v}"
                end
              else
                key = k.upcase
                if ["PUBDATE", "TIMESTAMP", "START_DATE", "END_DATE"].include? key and v.present?
                  value = v.strftime(PUBDATE_OUTPUT_FORMAT)
                else
                  value = v
                end
              end
              unless key == "CONTENT"
                h.tag!("tns:name", key, "type"=>"xs:string")
                if key == "AUTHORS" or key == "AUTHOREMAIL"
                  g.tag!("tns:value", "type"=>"xs:string") do |i|
                    if value.present?
                      i.cdata!(value)
                    end
                  end
                else
                  g.tag!("tns:value", value, "type"=>"xs:string")
                end
              end
            end
          end
          if images.present? or source.images.present?
            g.tag!("tns:feature") do |h|
              h.tag!("tns:name", "IMAGE", "type"=>"xs:string")
              if images.present?
                g.tag!("tns:value", images.first.image.url, "type"=>"xs:string")
              elsif source.images.present?
                g.tag!("tns:value", source.images.first.image.url, "type"=>"xs:string")
              end
            end
          end
            
        end
        g.tag!("tns:document-part", "part"=>"BODY", "id"=>"1") do |h|
          h.tag!("tns:content") do |i|
            i.cdata!(sanitized_content)
          end
        end
      end
      
    end
    xml.target!
  end

  # the "attributes" hash no longer contains everything we want to push as a feature to DSP
  # so this method returns the full feature list (attributes hash + whatever else)
  def feature_set
    set = attributes.merge({
      "source_uri" => source_uri,
      "categories" => publish_category
    })
    set.except("source_category", "category", "id", "created_at", "updated_at", "quarantine",
               "import_record_id", "published", "links", "start_date", "end_date",
               "links", "featured", "category_reviewed", "raw_content", "processed_content" )
  end

  # Export Gate Document directly before/after Pipeline processing
  def export_pre_pipeline_xml(repo, opts = {})
    options = { :body => self.to_new_xml }
    file_list = opts[:file_list] || Array.new

    res = OntotextController.post("#{repo.dsp_endpoint}/processPrePipeline", options)

    # TODO: Make check for erroneous response better
    unless res.body.nil? || res.body.empty?
      FileUtils.mkpath("#{export_path}/pre_pipeline")
      xml_path = "#{export_path}/pre_pipeline/#{guid}.xml"
      File.open(xml_path, "w+") { |f| f.write(res.body) }
      File.open("#{export_path}/pre_pipeline/#{guid}.html", "w+") { |f| f.write(sanitized_content) }
      file_list << xml_path
      return true
    else
      return false
    end
  end
    
  def export_post_pipeline_xml(repo, opts = {})
    options = { :body => self.to_new_xml }
    file_list = opts[:file_list] || Array.new

    res = OntotextController.post("#{repo.dsp_endpoint}/processPostPipeline", options)

    # TODO: Make check for erroneous response better
    unless res.body.nil? || res.body.empty?
      FileUtils.mkpath("#{export_path}/post_pipeline")
      xml_path = "#{export_path}/post_pipeline/#{guid}.xml"
      File.open(xml_path, "w+") { |f| f.write(res.body) }
      File.open("#{export_path}/post_pipeline/#{guid}.html", "w+") { |f| f.write(sanitized_content) }
      file_list << xml_path
      return true
    else
      return false
    end
  end

  # construct export path
  def export_path
    path = "#{Figaro.env.content_export_path}/#{source.name.gsub(" ", "_")}/#{pubdate.strftime("%Y")}/#{pubdate.strftime("%m")}/#{pubdate.strftime("%d")}"
  end

  # method that constructs an active relation
  # of contents based on a query hash of conditions
  # expects query_params to look like the params hash from a form
  def self.contents_query(query_params)
    # if the query contains a list of ids, use that
    if query_params[:ids].present?
      id_array = query_params[:ids].split(",").map { |i| i.strip.to_i }
      contents = Content.where(:id => id_array)
    else
      query = {
        quarantine: false # can't publish quarantined docs
      }
      if query_params[:source_id].present?
        query[:source_id] = query_params[:source_id].map { |s| s.to_i } 
      end
      if query_params[:import_location_id].present?
        query[:import_location_id] = query_params[:import_location_id].map { |s| s.to_i } 
      end

      repo = Repository.find(query_params[:repository_id]) if query_params[:repository_id].present?
      contents = Content.where(query)

      contents = contents.where("pubdate >= ?", Date.parse(query_params[:from])) if query_params[:from].present?
      contents = contents.where("pubdate <= ?", Date.parse(query_params[:to])) if query_params[:to].present?

      if query_params[:published] == "true" and repo.present?
        contents = contents.where("id IN (select content_id from contents_repositories where repository_id=#{repo.id})")
      elsif query_params[:published] == "false" and repo.present?
        contents = contents.where("id NOT IN (select content_id from contents_repositories where repository_id=#{repo.id})")
      end
    end
    return contents
  end

  def rdf_to_gate(repository)
    return OntotextController.rdf_to_gate(id, repository)
  end

  # for threaded contents
  # returns the original content of the thread by recursively iterating through parent
  # association
  def find_root_parent
    if parent.present?
      parent.find_root_parent
    else
      self
    end
  end

  # return ordered hash of downstream thread
  def get_downstream_thread
    if children.present?
      children_hash = {}
      children.each do |c|
        children_hash[c.id] = c.get_downstream_thread
      end
      children_hash
    else
      nil
    end
  end

  def get_ordered_downstream_thread(tier=0)
    downstream_thread = []
    if children.present?
      children.each do |c|
        downstream_thread << [c.id, tier+1]
        children2 = c.get_ordered_downstream_thread(tier+1)
        downstream_thread += children2 if children2.present?
      end
    end
    if downstream_thread.empty?
      nil
    else
      downstream_thread
    end
  end

  # returns full conversation regardless of where in the conversation this doc is
  def get_full_ordered_thread
    p = find_root_parent
    thread = [[p.id, 0]]
    downstream = p.get_ordered_downstream_thread
    if downstream.nil?
      thread
    else
      thread + p.get_ordered_downstream_thread
    end
  end

  # helper to retrieve the category that the content should be published with
  def publish_category
    if source.present? and source.category_override.present?
      source.category_override
    elsif category.present?
      category
    else 
      c = Category.find_or_create_by_name(source_category)
      if c.channel.present?
        c.channel.name
      else
        c.name
      end
    end
  end

  def has_active_promotion?
    promotions.where(active: true).count > 0
  end

  def has_active_promotion
    has_active_promotion?
  end

  def get_related_promotion(repo)
    results = query_promo_similarity_index(content, repo)
    results = query_promo_similarity_index(summary, repo) if results.empty?
    results = query_promo_similarity_index(title, repo) if results.empty?

    unless results.empty?
      uri = results[0][:uid].to_s
      idx = uri.rindex("/")
      id = uri[idx+1..uri.length]
    end
  end

  # callback function to update fields with repo info
  # this is run after publish to retrieve pipeline-processed
  # fields that we want to update in our DB.
  #
  # as of now, it only updates category
  def update_from_repo(repo)
    sparql = ::SPARQL::Client.new repo.sesame_endpoint
    response = sparql.query("
    # update from repo query
    prefix pub: <http://ontology.ontotext.com/publishing#>
    PREFIX sbtxd: <#{Figaro.env.document_prefix}>

    select ?category ?processed_content
    where {
      sbtxd:#{id} pub:content ?processed_content .
      OPTIONAL { sbtxd:#{id} pub:hasCategory ?category . }
    }")
    response_hash = response[0].to_hash
    # if we add more fields to be updated, we can iterate through the hash
    # and use send to update the content
    # not necessary for now.
    cat = response_hash[:category].to_s.split("/")[-1]
    cat = ContentCategory.find_or_create_by_name(cat).id unless cat.nil? 
    update_attributes(content_category_id: cat, processed_content: response_hash[:processed_content].to_s)
  end

  # Creates HTML-annotated, sanitized version of the raw_content that should be
  # as display-ready as possible
  def sanitized_content
    pre_sanitize_filters = [
      [:gsub!, ["\u{a0}",""]], # get rid of... this
      [:gsub!, [/<!--(?:(?!-->).)*-->/m, ""]], # get rid of HTML comments
      [:gsub!, [/<![^>]*>/, ""]], # get rid of doctype
      [:gsub!, [/<\/div><div[^>]*>/, "\n\n"]], # replace divs with new lines
    ]

    c = raw_content.gsub(/[[:alpha:]]\.[[:alpha:]]\./) {|s| s.upcase }
    pre_sanitize_filters.each {|f| c.send f[0], *f[1]}
    c = sanitize(c, tags: %w(span img a p br h1 h2 h3 h4 h5 h6 strong table td tr th ul ol li))
    doc = Nokogiri::HTML.parse(c)
    doc.search('//text()').each {|t| t.content = t.content.sub(/^[^>\n]*>\p{Space}*\z/, "") } # kill tag fragments
    is_newline = Proc.new do |t|
      not t.nil? and (t.matches? "br" or (t.matches? "p" and t.children.empty?))
    end
    remove_dup_newlines = Proc.new do |this_e, &block|
      while is_newline.call(this_e.next())
        block.call() if block
        this_e.next().remove()
      end
    end
    doc.search("p").each do |e|
      # This removes completely empty <p> tags... hopefully helps with excess whitespace issues
      if e.children.empty?
        e.remove
      # We saw content where only a text fragment was inside a "<p>" block, but then the following
      # tags "really" should have been part of that initial text fragment. This logic attempts to
      # remove excess whitespace in that and consolidate into 1 or more <p> blocks.
      elsif e.children.length == 1
        next_e = e.next()
        text = [e.content]
        until next_e.nil? do
          if next_e.text?
            text[-1] += next_e.text
          elsif is_newline.call(next_e)
            remove_dup_newlines.call(next_e)
          elsif next_e.matches? "strong"
            text.append "" if is_newline.call(next_e.next())
            text[-1] += " " if text[-1][-1] != " "
            text[-1] += next_e.to_html unless next_e.children.empty?
          else
            break
          end
          this_e = next_e
          next_e = next_e.next()
          this_e.remove()
        end
        text = text.delete_if {|t| t.empty? or t.blank?}
        new_node = Nokogiri::HTML.fragment("<p>#{text.shift}</p>")
        e = e.replace(new_node)
        text.reverse_each { |t| e.after("<p>#{t}</p>") }
      end
    end

    # try to remove any lingering inline CSS or bad text
    text_block = { text: "", nodes: [] }
    e_iter = doc.search("body").first.children.first unless doc.search("body").first.nil?
    until e_iter.nil? do
      if e_iter.text?
        text_block[:text] += e_iter.text
        text_block[:nodes].append e_iter
      elsif e_iter.matches? "br"
      else
        # This is a pretty lazy regex match for inline CSS... probably want something better
        text_block[:nodes].each {|n| n.remove() } if text_block[:text].match(/^.*{.*}$/) or text_block[:text].blank?
        text_block = { text: "", nodes: [] }
      end
      e_iter = e_iter.next()
    end

    # Get rid of excess whitespace caused by a ton of <br> tags
    doc.search("br").each {|e| remove_dup_newlines.call(e) }
    c = doc.search("body").first.to_html unless doc.search("body").first.nil?
    c ||= doc.to_html
    c = simple_format c

    BLACKLIST_BLOCKS.each do |b| 
      if /^\/(.*)\/([a-z]*)$/ =~ b.strip
        match = $~
        opts = 0
        match[2].each_char do |flag|
          case flag
          when "i"
            opts |= Regexp::IGNORECASE
          when "m"
            opts |= Regexp::MULTILINE
          when "x"
            opts |= Regexp::EXTENDED
          end
        end
        b = Regexp.new match[1], opts
      else 
        b = b.strip
      end
      c.gsub!(b, "")
    end

    c.gsub!(/(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)+/m, "")
    c.gsub(/(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)+/m, "")
  end

  def sanitized_content= new_content
    self.raw_content = new_content
  end

  private 

  def query_promo_similarity_index(query_term, repo)
    sparql = ::SPARQL::Client.new repo.sesame_endpoint
    clean_content = SparqlUtilities.sanitize_input(SparqlUtilities.clean_lucene_query(
                    ActionView::Base.full_sanitizer.sanitize(query_term)))
    query = File.read(Rails.root.join("lib", "queries", "query_promo_similarity_index.rq")) % 
            { content: clean_content, content_id: id }
    sparql.query(query)
  end

end
