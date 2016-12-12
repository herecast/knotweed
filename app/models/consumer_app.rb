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
  has_and_belongs_to_many :wufoo_forms
  has_and_belongs_to_many :messages
  has_and_belongs_to_many :organizations, after_add: :reindex_org_async

  def reindex_org_async(org)
    org.reindex_async
  end

  has_and_belongs_to_many :import_jobs
  belongs_to :repository

  validates_presence_of :uri
  validates_uniqueness_of :uri

  def self.current
    Thread.current[:consumer_app]
  end

  def self.current=(app)
    Thread.current[:consumer_app] = app
  end

  def self.default
    if Figaro.env.default_consumer_host?
      return self.where('uri ilike ?', "%#{Figaro.env.default_consumer_host}%").first
    end
  end
end
