# encoding: utf-8
# == Schema Information
#
# Table name: contents
#
#  id                       :integer          not null, primary key
#  title                    :string(255)
#  subtitle                 :string(255)
#  authors                  :string(255)
#  raw_content              :text
#  issue_id                 :integer
#  import_location_id       :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  copyright                :string(255)
#  guid                     :string(255)
#  pubdate                  :datetime
#  source_category          :string(255)
#  topics                   :string(255)
#  url                      :string(255)
#  origin                   :string(255)
#  language                 :string(255)
#  page                     :string(255)
#  authoremail              :string(255)
#  publication_id           :integer
#  quarantine               :boolean          default(FALSE)
#  doctype                  :string(255)
#  timestamp                :datetime
#  contentsource            :string(255)
#  import_record_id         :integer
#  source_content_id        :string(255)
#  parent_id                :integer
#  content_category_id      :integer
#  category_reviewed        :boolean          default(FALSE)
#  has_event_calendar       :boolean          default(FALSE)
#  channelized_content_id   :integer
#  published                :boolean          default(FALSE)
#  channel_type             :string(255)
#  channel_id               :integer
#  root_content_category_id :integer
#  delta                    :boolean          default(TRUE), not null
#  created_by               :integer
#  updated_by               :integer
#

require 'fileutils'
require 'builder'
include ActionView::Helpers::TextHelper
class Content < ActiveRecord::Base
  include Auditable

  belongs_to :issue
  belongs_to :import_location
  belongs_to :import_record

  has_many :annotation_reports
  has_many :category_corrections

  # NOTE: this relationship is tracking display of promotion banners with
  # contents, not the promotion of contents (which is handled through the promotion model).
  has_many :promotion_banners, through: :content_promotion_banner_impressions

  has_and_belongs_to_many :publish_records
  has_and_belongs_to_many :repositories, :uniq => true, after_add: :mark_published
  has_and_belongs_to_many :locations
  
  has_many :images, as: :imageable, inverse_of: :imageable, dependent: :destroy
  belongs_to :publication
  accepts_nested_attributes_for :images, allow_destroy: true
  attr_accessible :images_attributes, :images

  belongs_to :parent, class_name: "Content"
  has_many :children, class_name: "Content", foreign_key: "parent_id"

  has_many :promotions

  belongs_to :content_category
  belongs_to :root_content_category, class_name: 'ContentCategory'

  # mapping to content record that represents the channelized content
  belongs_to :channelized_content, class_name: "Content"
  has_one :unchannelized_original, class_name: "Content", foreign_key: "channelized_content_id"

  attr_accessible :title, :subtitle, :authors, :issue_id, :import_location_id, :copyright,
                :guid, :pubdate, :source_category, :topics, :url, :origin, 
                :language, :authoremail, :publication_id,
                :quarantine, :doctype, :timestamp, :contentsource, :source_content_id,
                :image_ids, :parent_id, :source_uri, :category,
                :content_category_id, :category_reviewed, :raw_content, 
                :sanitized_content, :channelized_content_id,
                :has_event_calendar, :channel_type, :channel_id, :channel,
                :location_ids, :root_content_category_id

  attr_accessor :tier # this is not stored on the database, but is used to generate a tiered tree
  # for the API

  validates_presence_of :raw_content, :title, if: :is_event?
  validates_presence_of :raw_content, :title, if: :is_market_post?

  # check if it should be marked quarantined
  before_save :mark_quarantined
  before_save :set_guid
  before_save :set_root_content_category_id

  # channel relationships
  belongs_to :channel, polymorphic: true, inverse_of: :content

  TMP_EXPORT_PATH = Rails.root + "/tmp/exports"

  scope :events, -> { joins(:content_category).where("content_categories.name = ? or content_categories.name = ?",
                                                     "event", "sale_event") }

  scope :externally_visible, -> { Content.joins(:publication)
        .joins("inner join content_categories_publications ccp on publications.id = ccp.publication_id AND contents.content_category_id = ccp.content_category_id")}

  scope :published, -> { where(published: true) }

  NEW_FORMAT = "New"
  EXPORT_FORMATS = [NEW_FORMAT]
  DEFAULT_FORMAT = NEW_FORMAT

  PUBDATE_OUTPUT_FORMAT = "%Y-%m-%dT%H:%M:%S"

  BASE_URI = "http://www.subtext.org/Document"

  # publish methods are string representations
  # of methods on the Content model
  # that are called via send on each piece of content
  EXPORT_TO_XML = "export_to_xml"
  EXPORT_PRE_PIPELINE = "export_pre_pipeline_xml"
  EXPORT_POST_PIPELINE = "export_post_pipeline_xml"
  PUBLISH_TO_DSP = "publish_to_dsp"
  PUBLISH_METHODS = [PUBLISH_TO_DSP, EXPORT_TO_XML, EXPORT_PRE_PIPELINE,
                     EXPORT_POST_PIPELINE]
  # set a default here so if it changes, 
  # we don't have to change the code in many different places
  DEFAULT_PUBLISH_METHOD = PUBLISH_TO_DSP

  # features that can be overwritten when we reimport
  REIMPORT_FEATURES = %w(title subtitle authors raw_content pubdate source_category topics 
                         url authoremail import_record)

  CATEGORIES = %w(beta_talk business campaign discussion event for_free lifestyle 
                  local_news nation_world offered presentation recommendation
                  sale_event sports wanted)

  BLACKLIST_BLOCKS = File.readlines(Rails.root.join('lib', 'content_blacklist.txt')) 

  # callback that is run after a contents_repositories entry is added
  # sets content.published = true IF the repository is the "production"
  # repository
  def mark_published(repo)
    if repo.id == Repository::PRODUCTION_REPOSITORY_ID
      update_attribute :published, true
    end
  end


  # holdover from when we used to use processed_content by preference.
  # Seemed easier to keep this method, but just make it point directly to raw content 
  # than to remove references to the method altogether
  def content
    raw_content
  end

  # if passed a repo, checks if this content was published in that repo
  # otherwise, checks if it is published in any repo
  def published?(repo=nil)
    if repo.present?
      repositories.include? repo
    else
      repositories.present?
    end
  end

  def document_uri
    "#{BASE_URI}/#{id}"
  end

  def source_uri
    "<http://www.subtext.org/#{publication.class.to_s}/#{publication.id}>"
  end

  def parent_uri
    "#{BASE_URI}/#{parent_id}" unless parent_id.nil?
  end

  def publication_name
    publication.try(:name)
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
      if ['image', 'images', 'content_category', 'location', 'source', 'edition', 'imagecaption', 'imagecredit', 'in_reply_to', 'categories', 'source_field'].include? key
        special_attrs[key] = v if v.present?
      elsif key == 'listserv_locations' || key == 'content_locations'
        data['location_ids'] = Location.get_ids_from_location_strings(v)
      elsif v.present?
        data[key] = v
      end
    end

    # if this has our proprietary 'X-Original-Content-Id' key in the header, it means this was created on our site.
    # if so, AND it's an event, it implies it's already been curated (i.e. 'has_event-calendar')
    original_content_id = original_event_instance_id = 0
    original_content_id = data['X-Original-Content-Id'] if data.has_key? 'X-Original-Content-Id'
    if original_content_id > 0
      c = Content.find(original_content_id)
      data['has_event_calendar'] = true if 'Event' == c.channel_type
    end
    # if this has our proprietary 'X-Original-Event-Instance-Id' key in the header, it means this was created on
    # our site so don't create new content. If so, AND it's an event, it implies it's already been curated (i.e. 'has_event-calendar')
    original_event_instance_id = data['X-Original-Event-Instance-Id'] if data.has_key? 'X-Original-Event-Instance-Id'
    if original_event_instance_id > 0
      c = EventInstance.find(original_event_instance_id).event.content
      data['has_event_calendar'] = true if 'Event' == c.channel_type
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
      if special_attrs.has_key? "source_field"
        source_field = special_attrs["source_field"].to_sym
      else
        source_field = :name
      end
      source = special_attrs["source"]
      if source_field == :name
        if organization
          # try to match content name exactly
          pub = Publication.where("organization_id = ? OR organization_id IS NULL", organization.id).find_by_name(source)
          # if that doesn't work, try a "LIKE" query
          pub = Publication.where("organization_id = ? OR organization_id IS NULL", organization.id).where("name LIKE ?", "%#{source}%").first if pub.nil?
          # if that still doesn't work, create a new publication
          pub = Publication.create(name: source, organization_id: organization.id) if pub.nil?

          content.publication = pub
        else
          content.publication = Publication.where("name LIKE ?", "%#{source}%").first
          content.publication = Publication.create(name: source) if content.publication.nil?
        end
      else # deal with special source_fields
        content.publication = Publication.where(source_field => source).first
      end
    end
    if special_attrs.has_key? "edition"
      edition = special_attrs["edition"]
      content.issue = Issue.where("issue_edition LIKE ?", "%#{edition}%").where(publication_id: content.publication_id, publication_date: content.pubdate).first
      # if not found, create a new one
      if content.issue.nil?
        content.issue = Issue.new(issue_edition: edition, publication_date: content.pubdate)
        content.issue.publication = content.publication if content.publication.present?
      end
    end
    if special_attrs.has_key? "categories"
      content.source_category = special_attrs['categories']
    end
    if special_attrs.has_key? 'content_category'
      content.category = special_attrs['content_category']
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
    if content.publication.present? and content.source_content_id.present?
      existing_content = Content.where(publication_id: content.publication_id, source_content_id: content.source_content_id).try(:first)
    end
    if existing_content.nil? and content.publication.present?
      existing_content = Content.where(publication_id: content.publication_id, guid: content.guid).try(:first)
    end
    if existing_content.present?
      # if existing content is there, rather than saving, we update
      # the whitelisted reimport attributes
      REIMPORT_FEATURES.each do |f|
        existing_content.send "#{f}=", content.send(f.to_sym) if content.send(f.to_sym).present?
      end

      existing_content.locations += content.locations
      content = existing_content
    end

    content.save!


    # if the content saves, add any images that came in
    # this has to be down here, not in the special_attributes CASE statement
    # because we don't want to create the images if the content doesn't save.
    if special_attrs.has_key? "image"
      # CarrierWave validation should take care of validating this for us
      content.create_or_update_image(special_attrs['image'], special_attrs['imagecaption'], special_attrs['imagecredit'])
    end

    # handle multiple images (initially from Wordpress import parser)
    if special_attrs.has_key? 'images'
      # CarrierWave validation should take care of validating this for us
      images = special_attrs['images']
      images.each do | img |
        content.create_or_update_image(img['image'], img['imagecaption'], img['imagecredit'])
      end
    end

    content
  end

  def create_or_update_image(url, caption, credit)
    # do we already have this image?
    current_image = Image.find_by_imageable_id_and_source_url(id, url)
    image_attrs = {
        remote_image_url: url,
        source_url: url
    }
    image_attrs[:caption] = caption if caption.present?
    image_attrs[:credit] = credit if credit.present?
    if current_image.present?
      images.update(current_image.id, image_attrs)
    else
      images.create(image_attrs)
    end
  end

  # check that doc validates our xml requirements
  # if not, mark it as quarantined
  def mark_quarantined
    if title.present? and publication.present? and pubdate.present? and strip_tags(sanitized_content).present?
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

  def set_root_content_category_id
    if content_category.present?
      self.root_content_category_id = content_category.parent_id || content_category.id
    else
      self.root_content_category_id = nil
    end
  end

  # catchall publish method that handles interacting w/ the publish record
  def publish(method, repo, record=nil, opts={})
    # do not allow publishing during BACKUPS
    if ImportJob.backup_start < Time.now and Time.now < ImportJob.backup_end
      return false
    end
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
        log.error("#{Time.now}: Export of #{self.id} failed (returned: #{result})")
        record.failures += 1 if record.present?
      end
    rescue => e
      log.error("#{Time.now}: Error exporting #{self.id}: #{e}")
      record.failures += 1 if record.present?
    end
    record.save if record.present?
    if opts[:download_result].present? and not file_list.nil? and file_list.length > 0
      opts[:download_result] = file_list[0]
    end

    if channel_type == 'Event'
      channel.set_event_instance_deltas
    end

    result
  end

  # Extracts mentions (e.g. Person, Organization, Keyphrases) from full annotations
  def extract_mentions_from_annotations(annotations)
    mentions = []
    annotations['annotation-sets'].each do |s| 
      s['annotation'].each do |a|
        value = nil
        a['feature-set'].each do |feature|
          value = feature['value']['value'] if feature['name']['name'] == "inst"
        end
        mentions << { type: a['type'], value: value }
      end
    end
    mentions
  end

  # Creates an Ontotext "recommendation" doc suitable for submission to the API
  # from annotations returned by the content extraction service
  def create_recommendation_doc_from_annotations(annotations)
    rec_doc = { id: annotations['id'],
                title: title,
                content: sanitized_content,
                published: pubdate.utc.iso8601,
                url: url,
                tags: [],
                keyphrases: [],
    }

    extract_mentions_from_annotations(annotations).each do |m|
      if ["Location", "Person", "Organization"].include? m[:type]
        rec_doc[:tags] << m[:value]
      else
        rec_doc[:keyphrases] << m[:value]
      end
    end

    rec_doc[:tags] = rec_doc[:tags].join(" ")
    rec_doc[:keyphrases] = rec_doc[:keyphrases].join(" ")

    [rec_doc]
  end

  # Updates this content's category based on the annotations from the CES 
  # If no category annotation is found, this is a no-op
  def update_category_from_annotations(annotations)
    cat = nil
    annotations['document-parts']['feature-set'].each do |feature|
      # if we get "CATEGORY" returned, use that to populate category
      # if not, try CATEGORIES
      if feature["name"]["name"] == "CATEGORY"
        cat= feature['value']['value']
      else
        if feature["name"]["name"] == "CATEGORIES" and !cat.present?
          cat= feature["value"]["value"]
        end
      end
    end

    if cat.present?
      cat_id = ContentCategory.find_or_create_by_name(cat).id 
      update_attributes(content_category_id: cat_id)
    end
  end

  # Persists this content to GraphDB as a series of tuples.
  def persist_to_graph_db(repo, annotations)
    #create/populate graph
    graph = RDF::Graph.new
    pub = RDF::Vocabulary.new("http://ontology.ontotext.com/publishing#")
    category = RDF::Vocabulary.new("http://data.ontotext.com/Category/")
    facets = RDF::Vocabulary.new("http://data.ontotext.com/facets/facetLink#")
    features = RDF::Vocabulary.new("http://data.ontotext.com/watt/Feature/")
    id_uri = RDF::URI(annotations['id'])

    graph << [RDF::URI(annotations['id']), RDF.type, pub['Document']]
    graph << [id_uri, pub['title'], title]
    graph << [id_uri, pub['creationDate'], pubdate.utc.iso8601]
    graph << [id_uri, pub['content'], sanitized_content]
    graph << [id_uri, pub['hasCategory'], category[publish_category]]
    graph << [id_uri, pub['annotatedContent'], JSON.generate(annotations)]

    extract_mentions_from_annotations(annotations).each do |m|
      graph << [id_uri, facets[m[:type]], RDF::URI(m[:value])]
    end

    sparql = ::SPARQL::Client.new repo.graphdb_endpoint

    #clean out existing annotatedContent for this uri
    query = File.read(Rails.root.join("lib", "queries", "remove_statements.rq")) %
            {content_id: id}
    sparql.update(query, { endpoint: repo.graphdb_endpoint + "/statements" })

    annotations['document-parts']['feature-set'].each do |feature|
     # populate features ONLY IF they have a value
      if not feature['value']['value'].empty?
        feature_key = features[SecureRandom.uuid]
        graph << [feature_key, RDF.type, pub['Feature']]
        graph << [feature_key, pub['featureName'], feature['name']['name']]
        graph << [feature_key, pub['featureValue'], feature['value']['value']]
        graph << [id_uri, pub['Feature'], feature_key]
      end
    end

    query = "INSERT DATA {"+graph.dump(:ntriples)+"}"

    sparql.update(query, { endpoint: repo.graphdb_endpoint + "/statements" })
    graph
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
  
  # Post to Ontotext's new CES & Recommendations API
  # - passes content thru pipeline (annotation)
  # - formats annotation and posts to recommendation engine
  # - persists content to graphdb and updates active promo if applicable
  # @todo investigate why we're passing opts
  # @param repo [Repo] the repo object
  # @param opts [Array] publish options e.g. :download_result 
  def publish_to_dsp(repo, opts={})
    annotate_resp = JSON.parse(
      OntotextController.post(repo.annotate_endpoint + '/extract', 
        { body: to_new_xml,
          headers: { 'Content-type' => "application/vnd.ontotext.ces.document+xml;charset=UTF-8",
                     'Accept' => "application/vnd.ontotext.ces.document+json" }}))
    if annotate_resp['id'].include? document_uri
      update_category_from_annotations(annotate_resp)
      rec_doc = create_recommendation_doc_from_annotations(annotate_resp)

      response = OntotextController.post(repo.recommendation_endpoint + "/content?key=#{Figaro.env.ontotext_recommend_key}", 
          { headers: { "Content-type" => "application/json",
                       "Accept" => "application/json" },
            body: rec_doc.to_json } )

      if response["type"] == "SUCCESS"
        repositories << repo unless repositories.include? repo

        persist_to_graph_db(repo, annotate_resp);

        # trigger updating hasActivePromotion if publish succeeded
        if has_active_promotion?
          PromotionBanner.mark_active_promotion(self, repo)
        end

        # trigger updating hasPaidPromotion if publish succeeded
        if has_paid_promotion?
          PromotionBanner.mark_paid_promotion(self, repo)
        end

        return true
      end
    end

    return "failed to post doc: #{self.id}\nresponse:#{response.body}"
  end

  def to_new_xml(include_tags=false)
    xml = ::Builder::XmlMarkup.new
    xml.instruct!
    xml.tag!("tns:document", "xmlns:tns"=>"http://www.ontotext.com/DocumentSchema", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "id" => document_uri) do |f|

      f.tag!("tns:document-parts") do |g|
        f.tag!("tns:feature-set") do |g|
          feature_set.each do |k, v|
            g.tag!("tns:feature") do |h|
              if ["issue_id", "publication_id", "import_location_id", "parent_id"].include? k
                if k == "issue_id" and issue.present?
                  key, value = "ISSUE", issue.issue_edition
                elsif k == "publication_id" and publication.present?
                  key, value = "SOURCE", publication.name
                elsif k == "import_location_id" and import_location.present?
                  if import_location.status == ImportLocation::STATUS_GOOD
                    key, value = "LOCATION", import_location.city
                  end
                elsif k == "parent_id" and parent.present?
                  key, value = "PARENT", "#{BASE_URI}/#{v}"
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
          if images.present? or publication.images.present?
            g.tag!("tns:feature") do |h|
              h.tag!("tns:name", "IMAGE", "type"=>"xs:string")
              if images.present?
                g.tag!("tns:value", images.first.image.url, "type"=>"xs:string")
              elsif publication.images.present?
                g.tag!("tns:value", publication.images.first.image.url, "type"=>"xs:string")
              end
            end
          end
            
        end
        g.tag!("tns:document-part", "part"=>"BODY", "id"=>"1") do |h|
          h.tag!("tns:content") do |i|
            i.cdata!(publish_content(include_tags))
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
    # note: the second except here is temporary, because we can't remove the attr_accessors for these
    # until after the migrations are done, so we need to exclude these nonexistent fields here
    set.except("source_category", "category", "id", "created_at", "updated_at", "quarantine",
               "import_record_id", "published",
               "category_reviewed", "raw_content",
               "has_event_calendar", 'root_content_category_id', 'delta',
              'created_by', 'updated_by')
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
    path = "#{TMP_EXPORT_PATH}/#{publication.name.gsub(" ", "_")}/#{pubdate.strftime("%Y")}/#{pubdate.strftime("%m")}/#{pubdate.strftime("%d")}"
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
      if query_params[:publication_id].present?
        query[:publication_id] = query_params[:publication_id].map { |s| s.to_i } 
      end
      if query_params[:import_location_id].present?
        query[:import_location_id] = query_params[:import_location_id].map { |s| s.to_i } 
      end
      if query_params[:content_category_id].present?
        query[:content_category_id] = query_params[:content_category_id].map { |s| s.to_i } 
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

  # return thread of comment-type objects associated with self
  # NOTE: for simplicity, I'm ignoring tiers of comments here. We'll still return them...
  # but until told otherwise, this is the way we're doing it because it's much easier.
  def get_comment_thread(tier=0)
    if children.present?
      comments = []
      children.order('pubdate ASC').each do |c|
        if c.channel_type == 'Comment'
          c.tier = tier
          comments += [c]
          comments += c.get_comment_thread(tier+1)
        end
      end
      comments
    else
      []
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
    if publication.present? and publication.category_override.present?
      publication.category_override
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

  # used for the DSP to determine whether there is a promotion banner
  def has_active_promotion?
    PromotionBanner.for_content(id).active.count > 0
  end

  def has_active_promotion
    has_active_promotion?
  end

  def has_paid_promotion?
    PromotionBanner.for_content(id).paid.count > 0
  end

  def has_paid_promotion
    has_paid_promotion?
  end

  def get_related_promotion(repo)

    results = query_promo_similarity_index(content, repo)
    results = query_promo_similarity_index(title, repo) if results.empty?
    results = query_promo_random_paid(repo) if results.empty?
    results = query_promo_random(repo) if results.empty?

    #logger.debug "Get Promo: #{results.inspect}"

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
  #
  # TODO: decide whether we still need this method. publish_to_ontotext no longer uses it...
  def update_from_repo(repo)
    sparql = ::SPARQL::Client.new repo.sesame_endpoint
    response = sparql.query("
    # update from repo query
    prefix pub: <http://ontology.ontotext.com/publishing#>
    PREFIX sbtxd: <#{BASE_URI}/>

    select ?category 
    where {
      OPTIONAL { sbtxd:#{id} pub:hasCategory ?category . }
    }")
    unless response[0].nil?
	    response_hash = response[0].to_hash
	    # if we add more fields to be updated, we can iterate through the hash
	    # and use send to update the content
	    # not necessary for now.
	    cat = response_hash[:category].to_s.split("/")[-1]
	    cat = ContentCategory.find_or_create_by_name(cat).id unless cat.nil?
	    update_attributes(content_category_id: cat)
		end
  end

  # returns the content for sending to the DSP for annotation
  def publish_content(include_tags=false)
    pub_content = sanitized_content
    if include_tags
      pub_content
    else
      strip_tags(pub_content)
    end
  end

  # cleans raw_content for text emails
  #
  # @return string with HTML tags and escaped spaces (&nbsp;) removed and hyperlinks changed to text surrounded by ()
  def raw_content_for_text_email
    return raw_content if raw_content.nil?
    # strip all tags but <a> and their href attributes and translate &nbsp; to space
    text = sanitize(raw_content, {tags: %w(a), attributes: %w(href)}).gsub(/&nbsp;/, ' ')
    # now rewrite <a href=http://...>xxx</a> to xxx (http://xxx)
    text.gsub(/\<a.*?href\=['"](?<href>.*?)['"]\>(?<target>.*?)\<\/a\>/, '\k<target> (\k<href>)')
  end

  # Creates sanitized version of title - at this point, just stripping out listerv towns
  def sanitized_title
    if title.present?
      title.gsub(/\[[^\]]+\]/, "").strip
    else
      nil
    end
  end

  # Creates HTML-annotated, sanitized version of the raw_content that should be
  # as display-ready as possible
  def sanitized_content
    return raw_content if raw_content.nil?
    pre_sanitize_filters = [
      # HACK: not sure exactly what this is...
      #[:gsub!, ["\u{a0}",""]], # get rid of... this
      [:gsub!, [/<!--(?:(?!-->).)*-->/m, ""]], # get rid of HTML comments
      [:gsub!, [/<![^>]*>/, ""]], # get rid of doctype
      [:gsub!, [/<\/div><div[^>]*>/, "\n\n"]], # replace divs with new lines
    ]

    c = raw_content.gsub(/[[:alpha:]]\.[[:alpha:]]\./) {|s| s.upcase }
    pre_sanitize_filters.each {|f| c.send f[0], *f[1]}
    doc = Nokogiri::HTML.parse(c)

    # this line is designed to handle content imported from Wordpress that had an image at the top of the content
    # and potentially other images.  The first image would duplicate our only (currently-supported) image,
    # which is also needed for tile view.  This line pulls the first <a ...><img ...></a> set and leaves the second and
    # subsequent so those images actually display as intended and built in Wordpress.  Note that they pull the images
    # from the Wordpress media library, not our AWS store.  Leaving the links in raw_content and post-processing
    # here allows us to go back in the near future and implement a better solution for multiple images JGS 20150605
    process_wp_content(doc)

    doc.search("style").each {|t| t.remove() }
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
    e_iter = doc.search("body").first.children.first unless doc.search("body").first.nil?
    until e_iter.nil? do
      if e_iter.text?
        e_iter.remove() if e_iter.text.match(/\A.*{.*}\Z/) or e_iter.text.blank?
      elsif e_iter.matches? "br"
      else
      end
      e_iter = e_iter.next()
    end

    # Get rid of excess whitespace caused by a ton of <br> tags
    doc.search("br").each {|e| remove_dup_newlines.call(e) }
    c = doc.search("body").first.to_html unless doc.search("body").first.nil?
    c ||= doc.to_html
    c = sanitize(c, tags: %w(span div img a p br h1 h2 h3 h4 h5 h6 strong em table td tr th ul ol li))
    c = simple_format c
    c.gsub!(/(<a href="http[^>]*)>/, '\1 target="_blank">')

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

    c.gsub!(/(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)+/m, "<br />")
    c.gsub!(/(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)+/m, "")
    Rinku.auto_link c
  end


  def process_wp_content(doc)

    # if record hasn't been saved yet, no point in doing this processing because we need the id.
    return if self.id.nil?

    #wp_images = doc.css('a img[class*=wp-image]')
    wp_images = doc.css('img')
    return if wp_images.empty?

    # our code already displays the first image, so just pull it from the content.
    wp_images.first.remove()

    bucket = Figaro.env.aws_bucket_name

    doc.css('img').each do |img|
      # rewrite img src URL.  This has to be done here because we don't know the content_id when
      # the parser is run by import_job#traverse_input_tree.
      imgName = File.basename(img['src'])
      img['src'] = "https://#{bucket}.s3.amazonaws.com/content/#{self.id}/" + imgName

      image = Image.find_by_imageable_id_and_image(self.id, imgName)
      img_caption = image.caption if image.present?
      img.add_next_sibling("<div class=\"image-caption\"><p>#{img_caption}</p></div>") if img_caption.present?
    end

  end

  def sanitized_content= new_content
    self.raw_content = new_content
  end

  # removes boilerplate
  def remove_boilerplate
    return raw_content if raw_content.nil?

    c = raw_content

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

    c.gsub!(/(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)+/m, "<br />")
    c.gsub(/(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)(?:[\n]+|<br(?:\ \/)?>|<p>(?:[\n]+|<br(?:\ \/)?>|[\s]+|[[:space:]]+|(?:\&#160;)+)?<\/p>)+/m, "")

  end

  # returns true if content has attached event
  def is_event?
    channel_type.present? and channel_type == "Event"
  end

  def is_market_post?
    channel_type.present? and channel_type == "MarketPost"
  end


  def self.truncated_content_fields
    [:id, :title,:pubdate, :authors, :category, 
     :parent_category, :publication_name, :publication_id,
     :parent_uri, :category_reviewed, :authoremail, :subtitle]
  end

  # Checks if a content is within its source's external_categories
  #
  # @return [Boolean]
  def externally_visible
    if publication.try(:external_categories).include? try(:content_category)
      true
    else
      false
    end
  end

  # pings a repository to retrieve similar content
  # and returns array of related content objects
  #
  # @param repo [Repository] repository to query
  # @param num_similar [Integer] number of results to return
  # @return [Array<Content>] list of similar content
  def similar_content(repo, num_similar=6)
    # some logic in here that I don't truly know the purpose of...
    # note -- the "category" method being called on self here
    # returns the text label of the associated content_category
    if ["event", "market", "offered", "wanted", "for_free", "sale_event"].include? category
      extra_param = "&mlt.boostexpr=recip(ms(NOW/HOUR,published),2.63e-10,1,1)"
    else
      extra_param = ''
    end

    similar_url = repo.recommendation_endpoint + '/recommend/contextual?contentid=' +
      uri + "&key=#{Figaro.env.ontotext_recommend_key}" +
      "&count=#{num_similar}" + "&sort=rel" + extra_param

    response = HTTParty.get(similar_url)
    if response.fetch('articles', nil)
      similar_ids = response['articles'].map do |art|
        art['id'].split('/')[-1].to_i
      end
      Content.where(id: similar_ids).includes(:content_category)
    else
      []
    end
  end

  def uri
    CGI.escape(BASE_URI + "/#{id}")
  end

  # accepts symbol reference to a count field that needs to be 
  # incremented and needs to skip callbacks
  #
  # @param attr_name [Symbol] the attribute to iterate; `:view_count`, `:comment_count`, `:commenter_count`
  def increment_count_attr!(attr_name)
    update_column attr_name, send(attr_name)+1
  end

  private

  def query_promo_similarity_index(query_term, repo)

    sparql = ::SPARQL::Client.new repo.sesame_endpoint
    clean_content = SparqlUtilities.sanitize_input(SparqlUtilities.clean_lucene_query(
                    ActionView::Base.full_sanitizer.sanitize(query_term)))
    query = File.read(Rails.root.join("lib", "queries", "query_promo_similarity_index.rq")) % 
            { content: clean_content, content_id: id }
    begin
      sparql.query(query)
    rescue
      return []
    end
  end

  def query_promo_random_paid(repo)
    sparql = ::SPARQL::Client.new repo.sesame_endpoint
    query = File.read(Rails.root.join("lib", "queries", "query_promo_random_paid.rq")) %
            { content_id: id }
    sparql.query(query)
  end

  def query_promo_random(repo)
    sparql = ::SPARQL::Client.new repo.sesame_endpoint
    query = File.read(Rails.root.join("lib", "queries", "query_promo_random.rq")) %
            { content_id: id }
    sparql.query(query)
  end

end
