module Jobs
  module JobController

    def run_job
      @job = controller_name.classify.constantize.find(params[:id])
      unless @job.status == "running" or @job.status == "queued"
        @job.enqueue_job
      end
      respond_to do |format|
        format.js { render "admin/jobs/run_job" }
      end
      
    end
  
    def cancel_job
      @job = controller_name.classify.constantize.find(params[:id])
      @job.cancel_scheduled_runs
      respond_to do |format|
        format.js { render "admin/jobs/cancel_job" }
      end
    end

    def destroy
      @job = controller_name.classify.constantize.destroy(params[:id])
      respond_to do |format|
        format.js { render "admin/jobs/destroy" }
      end
    end

  end
end
