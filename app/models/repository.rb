# == Schema Information
#
# Table name: repositories
#
#  id                      :integer          not null, primary key
#  name                    :string(255)
#  dsp_endpoint            :string(255)
#  sesame_endpoint         :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  graphdb_endpoint        :string(255)
#  annotate_endpoint       :string(255)
#  solr_endpoint           :string(255)
#  recommendation_endpoint :string(255)
#

class Repository < ActiveRecord::Base
  attr_accessible :dsp_endpoint, :name, :sesame_endpoint,
    :recommendation_endpoint

  validates_presence_of :dsp_endpoint, :sesame_endpoint, :name

  has_many :publish_jobs
  has_many :annotation_reports

  has_and_belongs_to_many :contents, :uniq => true

  # used to determine whether or not to mark contents "published"
  # defaults to 3, but can be overridden in app.yml
  PRODUCTION_REPOSITORY_ID = Figaro.env.respond_to?(:production_repository_id) ? Figaro.env.production_repository_id.to_i : 3

  def self.production_repo
    Repository.find(PRODUCTION_REPOSITORY_ID)
  end

end
