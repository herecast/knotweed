require 'sidekiq/api'

module Jobs
  module ScheduledJob
    def self.included(base)
      base.extend(ClassMethods)
    end

    # cancel scheduled runs by removing the Sidekiq job referenced from the ScheduledSet queue
    def cancel_scheduled_runs
      jobs = Sidekiq::ScheduledSet.new.
        select{ |job| job.args[0]["job_id"] == self.sidekiq_jid }
      jobs.each(&:delete)
      # if status was scheduled, change to blank
      # otherwise (in scenario where job just succeeded or failed)
      # leave status be
      attrs = {
        sidekiq_jid: nil,
        next_scheduled_run: nil,
        status: 'failed'
      }
      if self.status == "scheduled"
        attrs[:status] = nil
      end
      self.update! attrs
    end

  end
end
