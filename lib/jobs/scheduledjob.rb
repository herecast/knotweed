require 'sidekiq/api'

module Jobs
  module ScheduledJob
    def self.included(base)
      base.extend(ClassMethods)
    end

    # cancel scheduled runs by removing any Delayed::Job
    # records pointing to this job
    def cancel_scheduled_runs
      Sidekiq::ScheduledSet.new.find(self.sidekiq_jid).delete
      # if status was scheduled, change to blank
      # otherwise (in scenario where job just succeeded or failed)
      # leave status be
      if self.status == "scheduled"
        self.update_attribute :status, ""
      end
    end

  end
end
