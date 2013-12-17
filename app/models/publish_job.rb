require 'jobs/scheduledjob'

class PublishJob < ActiveRecord::Base

  include Jobs::ScheduledJob
  QUEUE = 'publishing'

  belongs_to :organization
  has_many :publish_records

  serialize :query_params, Hash

  attr_accessible :frequency, :organization_id, :publish_method, :query_params, :status,
                  :archive, :error, :name, :description

  after_destroy :cancel_scheduled_runs

  default_scope { where archive: false }

  # publish methods are string representations
  # of methods on the Content model
  # that are called via send on each piece of content
  POST_TO_ONTOTEXT = "post_to_ontotext"
  EXPORT_TO_XML = "export_to_xml"
  PUBLISH_METHODS = [POST_TO_ONTOTEXT, EXPORT_TO_XML]

  QUERY_PARAMS_FIELDS = %w(source_id from to location_id published)
  
  validates :publish_method, inclusion: { in: PUBLISH_METHODS }, allow_nil: true

  # determine publish method and construct
  # Content query from query_params hash
  def perform
    record = last_publish_record
    Content.contents_query(query_params).find_each(batch_size: 500) do |c|
      record.contents << c
      c.publish(publish_method, record)
    end
  end

  # status hooks
  def enqueue(job)
    update_attribute(:status, "queued")
  end

  def success(job)
    update_attribute(:status, "success")
  end

  def error(job, exception)
    update_attributes(:status => "failed")
  end

  def failure(job)
    update_attribute(:status, "failed")
  end

  def before(job)
    update_attribute(:status, "running")
    publish_records.create
  end

  def enqueue_job
    Delayed::Job.enqueue self, queue: QUEUE
  end

  def contents_count
    Content.contents_query(query_params).count
  end

  def last_publish_record
    publish_records.order("created_at DESC").first
  end

  # returns time last run at
  def last_run_at
    last_publish_record.try(:created_at)
  end

end
