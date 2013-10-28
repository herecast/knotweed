class Content < ActiveRecord::Base
  
  belongs_to :issue
  belongs_to :location
  
  has_many :images, as: :imageable, inverse_of: :imageable, dependent: :destroy
  belongs_to :contentsource, class_name: "Publication", foreign_key: "contentsource_id"
  accepts_nested_attributes_for :images, allow_destroy: true
  attr_accessible :images_attributes

  attr_accessible :title, :subtitle, :authors, :content, :issue_id, :location_id, :copyright
  attr_accessible :guid, :pubdate, :categories, :topics, :summary, :url, :origin, :mimetype
  attr_accessible :language, :page, :wordcount, :authoremail, :contentsource_id, :file
  attr_accessible :quarantine, :contentsource_id, :doctype, :timestamp
  
  #before_save :inherit_issue_location
  
  default_scope :include => :issue, :order => "issues.publication_date DESC, contents.created_at DESC"

  # check if it should be marked quarantined
  before_save :mark_quarantined

  rails_admin do
    list do
      filters [:contentsource, :issue, :title, :authors]
      items_per_page 100
      sort_by :pubdate, :contentsource
      field :pubdate
      field :contentsource
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
  def self.create_from_import_job(data)
    # pull special attributes out of the data hash
    special_attrs = {}
    ['location', 'source', 'contentsource', 'edition'].each do |key|
      if data.has_key? key
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
    if special_attrs.has_key? "source" or special_attrs.has_key? "contentsource"
      source = special_attrs["source"]
      # if no source, try contentsource
      source = special_attrs["contentsource"] if source.nil?
      content.contentsource = Publication.where("name LIKE ?", "%#{source}%").first
      content.contentsource = Publication.create(name: source) if content.contentsource.nil?
    end
    if special_attrs.has_key? "edition"
      edition = special_attrs["edition"]
      content.issue = Issue.where("issue_edition LIKE ?", "%#{edition}%").where(publication_id: content.contentsource_id, publication_date: content.pubdate).first
      # if not found, create a new one
      if content.issue.nil?
        content.issue = Issue.new(issue_edition: edition, publication_date: content.pubdate)
        content.issue.publication = content.contentsource if content.contentsource.present?
      end
    end
      
    content.save!
    content
  end

  # check that doc validates our xml requirements
  # if not, mark it as quarantined
  def mark_quarantined
    unless title.present? and contentsource.present? and pubdate.present?
      self.quarantine = true
    end
  end

  
end
