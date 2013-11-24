module Jobs
  module ScheduledJob
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def method_added(name)
        if name.to_s == "perform" && !@redefined
          @redefined = true
          alias_method_chain :perform, :schedule
        end
      end
    end

    def schedule
      if self.try(:frequency).present? and self.frequency != 0
        self.frequency.hours.from_now
      else
        nil
      end
    end

    def schedule!
      # avoid repeating indefinitely in tests
      unless Rails.env == "test"
        Delayed::Job.enqueue self, { :priority => 0, :run_at => self.schedule } if self.schedule 
      end
    end
    
    def perform_with_schedule
      perform_without_schedule
      self.schedule!
    end

    # gets next scheduled run
    # returns nil if not scheduled to run
    def next_scheduled_run
      job = Delayed::Job.where("handler LIKE ? AND handler LIKE '% id: ?\n%' AND run_at > ?", "%#{self.class.to_s}%", id, Time.now).order("run_at ASC").first
      job ? job.run_at : nil
    end
    
    # cancel scheduled runs by removing any Delayed::Job
    # records pointing to this job
    def cancel_scheduled_runs
      Delayed::Job.where("handler LIKE ? AND handler LIKE '% id: ?%'", "%#{self.class.to_s}%", id).delete_all
    end

  end
end
