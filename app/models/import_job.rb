# == Schema Information
#
# Table name: import_jobs
#
#  id                    :integer          not null, primary key
#  parser_id             :integer
#  name                  :string(255)
#  config                :text
#  source_uri            :string(255)
#  job_type              :string(255)
#  organization_id       :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  status                :string(255)
#  frequency             :integer          default(0)
#  archive               :boolean          default(FALSE), not null
#  run_at                :datetime
#  stop_loop             :boolean          default(TRUE)
#  automatically_publish :boolean          default(FALSE)
#  repository_id         :integer
#  publish_method        :string(255)
#  sidekiq_jid           :string
#  next_scheduled_run    :datetime
#  inbound_prefix        :string
#  outbound_prefix       :string
#

require 'find'
require 'json'
require "builder"
require 'fileutils'
require 'uri'
require 'sidekiq/api'

class ImportJob < ActiveRecord::Base

  QUEUE = "imports"
  PARSER_PATH = "#{Rails.root}/lib/parsers"

  # these have to be kept as strings
  BACKUP_START = Figaro.env.backup_start? ? Figaro.env.backup_start : "2:45 am"
  BACKUP_END = Figaro.env.backup_end? ? Figaro.env.backup_end : "3:45 am"

  belongs_to :organization
  belongs_to :parser
  belongs_to :repository
  has_many :import_records

  has_many :notifiers, as: :notifyable
  has_many :notifyees, through: :notifiers, class_name: "User", source: "user"

  validates :status, inclusion: { in: %w(failed running success scheduled) }, allow_nil: true

  validates :source_uri, absence: true, if: :s3_fields_present?
  validates :inbound_prefix, :outbound_prefix, absence: true, if: 'source_uri.present?'

  after_destroy :cancel_scheduled_runs

  default_scope { where archive: false }

  serialize :config, Hash

  CONTINUOUS = "continuous"
  AD_HOC = "ad_hoc"
  RECURRING = "recurring"
  JOB_TYPES = [CONTINUOUS, AD_HOC, RECURRING]

  before_validation :set_stop_loop

  def s3_fields_present?
    inbound_prefix.present? and outbound_prefix.present?
  end

  # returns either source_uri or a constructed S3 URL based on the fields;
  # currently only used in logging
  def full_import_path
    if source_uri.present?
      source_uri
    else
      "s3://#{Figaro.env.import_bucket}/#{inbound_prefix}"
    end
  end

  def self.backup_start
    Chronic.parse(BACKUP_START)
  end

  def self.backup_end
    Chronic.parse(BACKUP_END)
  end

  # if job type is continuous and the update call is not intentionally
  # changing stop_loop (which happens from ImportWorker and import_jobs_controller,
  # then ensure stop_loop is FALSE for continuous jobs
  def set_stop_loop
    if job_type == CONTINUOUS
      if job_type_changed? # if someone converted it to a continuous job...
        self.stop_loop = false
      # else do nothing 
      end
    else
      self.stop_loop = true
    end
    true
  end

  def next_run_time
    if frequency? and frequency != 0
      prev_run = last_run_at || run_at || Time.current
      if ImportJob.backup_start < Time.current and Time.current < ImportJob.backup_end
        new_start = ImportJob.backup_end
      else
        new_start = prev_run + frequency.minutes
      end
      new_start
    else
      run_at # can be nil
    end
  end

  # just a wrapper so the two job types can share the JobController module
  # even though they differ in Workers
  def enqueue_job
    ImportWorker.set(wait_until: next_run_time).perform_later(self)
  end

  def save_config(parameters)
    update_attribute(:config, parameters)
  end

  # returns the most recent import record
  def last_import_record
    import_records.order("created_at DESC").first
  end

  # returns time last run at
  def last_run_at
    last_import_record.try(:created_at)
  end

  # cancel scheduled runs by removing the Sidekiq job referenced from the ScheduledSet queue
  def cancel_scheduled_runs
    jobs = Sidekiq::ScheduledSet.new.
      select{ |job| job.args[0]["job_id"] == sidekiq_jid }
    jobs.each(&:delete)
    # if status was scheduled, change to blank
    # otherwise (in scenario where job just succeeded or failed)
    # leave status be
    attrs = {
      sidekiq_jid: nil,
      next_scheduled_run: nil,
      status: 'failed'
    }
    if status == "scheduled"
      attrs[:status] = nil
    end
    update! attrs
  end
end
