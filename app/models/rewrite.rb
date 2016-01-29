class Rewrite < ActiveRecord::Base
  include Auditable
  attr_accessible :destination, :source
  validates_presence_of :destination, :source
  validates_uniqueness_of :source
  
  before_save { |rewrite| rewrite.source = rewrite.source.downcase }
end
