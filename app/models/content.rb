class Content < ActiveRecord::Base
  
  belongs_to :issue
  belongs_to :location
  
  has_many :images, as: :imageable, inverse_of: :imageable, dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true
  attr_accessible :images_attributes
  
  attr_accessible :authors, :content, :issue_id, :location_id, :subject, :subtitle, :title, :source, :date_range_from, :date_range_to
  
  validates_presence_of :issue
  before_save :inherit_issue_location
  
  default_scope :include => :issue, :order => "issues.publication_date DESC, contents.created_at DESC"
  
  # sets content location to issue location if it was left blank
  def inherit_issue_location
    if self.location.nil?
      self.location = self.issue.location
    end
  end
  
end
