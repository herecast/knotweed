require 'sidekiq/api'
class ScheduleListservDigestsJob < ApplicationJob
  def perform
    Listserv.where(send_digest: true).where('digest_send_time IS NOT NULL').each do |ls|
      time_to_run = ls.next_digest_send_time
      unless duplicate_scheduled_job?(ls) || duplicate_retry_job?(ls)
        ListservDigestJob.set(wait_until: time_to_run).perform_later(ls)
      end
    end
  end


  private
  #check to see if there is already a scheduled job for the listserv id
  def duplicate_scheduled_job?(listserv)
    scheduled_queue = Sidekiq::ScheduledSet.new
    scheduled_queue.any? { |job| check_for_duplicate(listserv, job) }
  end


  def duplicate_retry_job?(listserv)
    retry_queue = Sidekiq::RetrySet.new
    retry_queue.any? { |job| check_for_duplicate(listserv, job) }
  end

  def check_for_duplicate(listserv, job)
    job_args = job.args.first
    job_class = job_args['job_class']
    global_id = nil

    first_job_argument = job_args['arguments'].first
    if first_job_argument.is_a? Hash
      global_id = first_job_argument['_aj_globalid']
    end

    if global_id
      #split to global id value to an array to check the id easier
      global_id_elements = global_id.split('/')

      job_class_matches = job_class == "ListservDigestJob"

      #listserv id should be the last element after splitting
      id_matches = global_id_elements.last.to_s == listserv.id.to_s

      return job_class_matches && id_matches
    else
      return false
    end
  end
end
