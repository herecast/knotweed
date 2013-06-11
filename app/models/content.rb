class Content < ActiveRecord::Base
  
  belongs_to :issue
  belongs_to :location
  
  attr_accessible :authors, :content, :issue_id, :location_id, :subject, :subtitle, :title
  
  validates_presence_of :issue
  
  default_scope :include => :issue, :order => "issues.publication_date DESC, contents.created_at DESC"
  
end
