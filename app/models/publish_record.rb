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
