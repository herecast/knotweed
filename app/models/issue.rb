# == Schema Information
#
# Table name: issues
#
#  id                 :integer          not null, primary key
#  issue_edition      :string(255)
#  organization_id    :integer
#  copyright          :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  import_location_id :integer
#  publication_date   :datetime
#

class Issue < ActiveRecord::Base
  attr_accessible :copyright, :issue_edition, :publication_date, :organization_id, :import_location_id
  
  belongs_to :organization
  belongs_to :import_location
  has_many :contents
  
  validates_presence_of :organization

  def name
    issue_edition
  end
  
end
