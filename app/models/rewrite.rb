class Rewrite < ActiveRecord::Base
  include Auditable
  attr_accessible :destination, :source
  validates_presence_of :destination, :source
  validates_uniqueness_of :source
end
