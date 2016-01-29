# == Schema Information
#
# Table name: rewrites
#
#  id          :integer          not null, primary key
#  source      :string(255)
#  destination :string(255)
#  created_by  :integer
#  updated_by  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Rewrite < ActiveRecord::Base
  include Auditable
  attr_accessible :destination, :source
  validates_presence_of :destination, :source
  validates_uniqueness_of :source
  
  before_save { |rewrite| rewrite.source = rewrite.source.downcase }
end
