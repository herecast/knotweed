module Jobs
  module JobController

    def run_job
      @job = controller_name.classify.constantize.find(params[:id])
      subscribe_user(@job)
      unless @job.status == "running" or @job.status == "queued"
        @job.enqueue_job
      end

      respond_to do |format|
        format.js { render "jobs/run_job" }
      end
    end
  
    def cancel_job
      @job = controller_name.classify.constantize.find(params[:id])
      @job.cancel_scheduled_runs
      respond_to do |format|
        format.js { render "jobs/cancel_job" }
      end
    end

    def destroy
      @job = controller_name.classify.constantize.destroy(params[:id])
      respond_to do |format|
        format.js { render "jobs/destroy" }
      end
    end

    def archive
      @job = controller_name.classify.constantize.find(params[:id])
      @job.update_attribute(:archive, true)
      respond_to do |format|
        format.js { render "jobs/archive" }
      end
    end

    def subscribe_user(job)
      if job.respond_to? :notifyees and current_user.present?
        job.notifyees << current_user
      end
    end

  end
end
