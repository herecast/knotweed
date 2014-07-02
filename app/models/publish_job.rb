require 'jobs/scheduledjob'
require 'zip'

class PublishJob < ActiveRecord::Base

  include Jobs::ScheduledJob
  QUEUE = 'publishing'

  belongs_to :organization
  has_many :publish_records

  has_many :notifiers, as: :notifyable
  has_many :notifyees, through: :notifiers, class_name: "User", source: "user"

  serialize :query_params, Hash

  attr_accessible :frequency, :organization_id, :publish_method, :query_params, :status,
                  :archive, :error, :name, :description

  after_destroy :cancel_scheduled_runs

  default_scope { where archive: false }

  QUERY_PARAMS_FIELDS = %w(source_id from to import_location_id published ids repository_id)
  
  validates :publish_method, inclusion: { in: Content::PUBLISH_METHODS }, allow_nil: true

  # determine publish method and construct
  # Content query from query_params hash
  def perform
    begin
      record = last_publish_record
      if query_params[:repository_id].present?
        repo = Repository.find query_params[:repository_id]
      else
        repo = nil
      end
      Content.contents_query(query_params).find_each(batch_size: 500) do |c|
        record.contents << c
        c.publish(publish_method, repo, record)
      end
      log = record.log_file
      log.info("failures: #{record.failures}")
      log.info("items published: #{record.items_published}")
      create_file_archive(record) unless record.files.empty?
    rescue => e
      log.error("Error creating file archive: #{e}\n#{e.backtrace.join("\n")}")
    end
  end

  # Create a zipped archive of all files created by a publish job
  # Archives live at public/exports/job_id.zip
  def create_file_archive(record)
    FileUtils.mkpath(File.join("public", "exports"))

    zip_file_name = File.join("public", "exports", "#{record.id.to_s}.zip")

    Zip::File.open(zip_file_name, Zip::File::CREATE) do |zipfile|
      record.files.each {|f| zipfile.add(File.basename(f), f) }
    end
    self.file_archive = zip_file_name
    self.save
    JobMailer.file_ready(record).deliver
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
