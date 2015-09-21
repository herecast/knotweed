# == Schema Information
#
# Table name: consumer_apps
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  uri           :string(255)
#  repository_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class ConsumerApp < ActiveRecord::Base
  attr_accessible :name, :repository_id, :uri, :publication_ids

  has_and_belongs_to_many :wufoo_forms
  has_and_belongs_to_many :messages
  has_and_belongs_to_many :publications
  belongs_to :repository

  validates_presence_of :uri
  validates_uniqueness_of :uri

  def self.current
    Thread.current[:consumer_app]
  end

  def self.current=(app)
    Thread.current[:consumer_app] = app
  end
end
