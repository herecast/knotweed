module ImportJobsHelper
  
  def alert_class_for_status(status)
    if status == "success"
      "success"
    elsif status == "failed"
      "error"
    elsif status == "running"
      "info"
    else
      ""
    end
  end

  def action_button_for_job(job)
    if job.status == "running"
      # if job is continuously repeating job
      if job.try(:job_type) == ImportJob::CONTINUOUS
        if job.try(:stop_loop) # indicate job will stop after this run
          content_tag(:span, "stopping", { class: "btn btn-mini btn-danger disabled" })
        else # insert cancel button
          content_tag(:a, "Stop Job", { href: stop_ongoing_import_job_path(job), 
                                        class: "btn btn-mini btn-danger",
                                        data: { remote: true }})
        end
      else
        content_tag(:span, "in process", { class: "btn btn-mini btn-danger disabled" })
      end
    else
      if job.next_scheduled_run.nil?
        if job.run_at.present?
          button_text = "Schedule Job"
        else
          button_text = "Run Job"
        end
        content_tag(:a, button_text, { href: get_path_for_job_action("run", job), data: { remote: true }, class: "btn btn-mini btn-success" })
      else
        content_tag(:a, "Cancel Scheduled Runs", { href: get_path_for_job_action("cancel", job), data: { remote: true, method: :delete }, class: "btn-mini btn-danger btn" })
      end
    end
  end

  def get_path_for_job_action(action, job)
    if job.class == PublishJob
      if action == "run"
        run_publish_job_path(job)
      elsif action == "cancel"
        cancel_publish_job_path(job)
      end
    elsif job.class == ImportJob
      if action == "run"
        run_import_job_path(job)
      elsif action == "cancel"
        cancel_import_job_path(job)
      end
    end
  end
      
  
end
