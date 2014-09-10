class ConsumerApp < ActiveRecord::Base
  attr_accessible :name, :repository_id, :uri

  has_and_belongs_to_many :wufoo_forms
  has_and_belongs_to_many :messages
  belongs_to :repository

  validates_presence_of :uri
  validates_uniqueness_of :uri
end
