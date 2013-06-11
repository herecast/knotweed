class Content < ActiveRecord::Base
  
  belongs_to :issue
  belongs_to :location
  
  attr_accessible :authors, :content, :issue_id, :location_id, :subject, :subtitle, :title
  
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
