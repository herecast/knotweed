class Content < ActiveRecord::Base
  
  belongs_to :issue
  belongs_to :location
  
  has_many :images, as: :imageable, inverse_of: :imageable, dependent: :destroy
  belongs_to :contentsource, class_name: Publication
  accepts_nested_attributes_for :images, allow_destroy: true
  attr_accessible :images_attributes

  attr_accessible :title, :subtitle, :authors, :content, :issue_id, :location_id, :copyright
  attr_accessible :guid, :pubdate, :categories, :topics, :summary, :url, :origin, :mimetype
  attr_accessible :language, :page, :wordcount, :authoremail, :contentsource_id, :file
  attr_accessible :quarantine, :contentsource_id
  
  #before_save :inherit_issue_location
  
  default_scope :include => :issue, :order => "issues.publication_date DESC, contents.created_at DESC"

  # check if it should be marked quarantined
  before_save :mark_quarantined
  
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
    content = Content.new
    # pull complex key/values out from data to use later
    if data.has_key? 'location'
      location = data['location']
      content.location = Location.where("city LIKE ?", "%#{location}%").first
      content.location = Location.new(city: location) if content.location.nil?
      data.delete "location"
    end
    if data.has_key? "source"
      source = data["source"]
      content.contentsource = Publication.where("name LIKE ?", "%#{source}%").first
      content.contentsource = Publication.create(name: source) if content.contentsource.nil?
      data.delete "source"
    end
    if data.has_key? "edition"
      edition = data["edition"]
      content.issue = Issue.where("issue_edition LIKE ? AND publication_id = ?", "%#{edition}%", content.contentsource_id).first
      # if not found, create a new one
      if content.issue.nil?
        content.issue = Issue.new(issue_edition: edition)
        content.issue.publication = content.contentsource if content.contentsource.present?
      end
      data.delete "edition"
    end
    content.update_attributes(data)
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
