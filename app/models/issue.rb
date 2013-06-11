class Issue < ActiveRecord::Base
  attr_accessible :copyright, :issue_edition, :publication_date, :publication_id, :location_id
  
  belongs_to :publication
  belongs_to :location
end
