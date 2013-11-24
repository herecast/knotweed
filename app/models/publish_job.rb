require 'jobs/scheduledjob'

class PublishJob < ActiveRecord::Base

  include Jobs::ScheduledJob

  belongs_to :organization

  serialize :query_params, Hash

  attr_accessible :frequency, :organization_id, :publish_method, :query_params, :status,
                  :archive, :error, :name, :description

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
    Content.contents_query(query_params).find_each(batch_size: 500) do |c|
      c.send(publish_method.to_sym)
    end
  end

  # status hooks
  def enqueue(job)
    self.update_attribute(:status, "queued")
  end

  def success(job)
    self.update_attribute(:status, "success")
  end

  def error(job, exception)
    self.update_attributes(status: "failed", error: exception)
  end

  def failure(job)
    self.update_attribute(:status, "failed")
  end

  def before(job)
    self.update_attribute(:status, "running")
    # self.publish_records.create
  end

  def enqueue_job
    Delayed::Job.enqueue self, queue: 'publishing'
  end

  def contents_count
    Content.contents_query(query_params).count
  end

end
