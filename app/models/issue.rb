class Issue < ActiveRecord::Base
  attr_accessible :copyright, :issue_edition, :publication_date, :publication_id, :import_location_id
  
  belongs_to :publication
  belongs_to :import_location
  has_many :contents
  
  validates_presence_of :publication

  rails_admin do
    object_label_method :issue_edition
  end

  def name
    issue_edition
  end
  
end
