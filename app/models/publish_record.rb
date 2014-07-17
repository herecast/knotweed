# == Schema Information
#
# Table name: publish_records
#
#  id              :integer          not null, primary key
#  publish_job_id  :integer
#  items_published :integer          default(0)
#  failures        :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class PublishRecord < ActiveRecord::Base
  belongs_to :publish_job
  has_and_belongs_to_many :contents
  attr_accessible :failures, :items_published

  def log_file
    Logger.new("#{Rails.root}/log/publish_records/#{id}.log")
  end

  def job
    publish_job
  end

  def files
    @file_list ||= Array.new
  end
end
