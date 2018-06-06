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
  belongs_to :organization
  has_many :contents
  
  validates_presence_of :organization

  def name
    issue_edition
  end
  
end
