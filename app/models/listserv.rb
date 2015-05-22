# == Schema Information
#
# Table name: listservs
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  reverse_publish_email :string(255)
#  import_name           :string(255)
#  active                :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class Listserv < ActiveRecord::Base
  has_many :promotion_listservs
  has_and_belongs_to_many :locations

  attr_accessible :active, :import_name, :name, :reverse_publish_email

  validates_uniqueness_of :reverse_publish_email
  
  default_scope { where active: true }
end
