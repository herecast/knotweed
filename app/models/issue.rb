class Issue < ActiveRecord::Base
  attr_accessible :copyright, :issue_edition, :publication_date, :publication_id
end
