# == Schema Information
#
# Table name: import_jobs
#
#  id                    :integer          not null, primary key
#  parser_id             :integer
#  name                  :string(255)
#  config                :text
#  source_path           :string(255)
#  job_type              :string(255)
#  organization_id       :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  status                :string(255)
#  frequency             :integer          default(0)
#  archive               :boolean          default(FALSE), not null
#  content_set_id        :integer
#  run_at                :datetime
#  stop_loop             :boolean          default(TRUE)
#  automatically_publish :boolean          default(FALSE)
#  repository_id         :integer
#  publish_method        :string(255)
#

require 'find'
require 'json'
require "builder"
require 'fileutils'
require 'uri'
require 'jobs/scheduledjob'

class ImportJob < ActiveRecord::Base

  include Jobs::ScheduledJob
  QUEUE = "imports"
  PARSER_PATH = "#{Rails.root}/lib/parsers"

  # these have to be kept as strings
  BACKUP_START = Figaro.env.backup_start? ? Figaro.env.backup_start : "2:45 am"
  BACKUP_END = Figaro.env.backup_end? ? Figaro.env.backup_end : "3:45 am"

  belongs_to :organization
  belongs_to :parser
  belongs_to :content_set
  belongs_to :repository
  has_many :import_records

  has_many :notifiers, as: :notifyable
  has_many :notifyees, through: :notifiers, class_name: "User", source: "user"
  has_and_belongs_to_many :consumer_apps

  validates :status, inclusion: { in: %w(failed running success scheduled) }, allow_nil: true

  after_destroy :cancel_scheduled_runs

  default_scope { where archive: false }

  serialize :config, Hash

  CONTINUOUS = "continuous"
  AD_HOC = "ad_hoc"
  RECURRING = "recurring"
  JOB_TYPES = [CONTINUOUS, AD_HOC, RECURRING]

  before_validation :set_stop_loop

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
    if job_type == CONTINUOUS and job_type_changed?
      stop_loop = false
    else
      stop_loop = true
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
      nil
    end
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
end
