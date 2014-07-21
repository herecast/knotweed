# == Schema Information
#
# Table name: repositories
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  dsp_endpoint    :string(255)
#  sesame_endpoint :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Repository < ActiveRecord::Base
  attr_accessible :dsp_endpoint, :name, :sesame_endpoint

  validates_presence_of :dsp_endpoint, :sesame_endpoint, :name

  has_many :publish_jobs
  has_many :annotation_reports

  has_and_belongs_to_many :contents, :uniq => true
end
