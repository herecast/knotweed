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
      content_tag(:span, "in process", { class: "btn btn-danger disabled" })
    elsif job.status == "queued"
      content_tag(:span, "queued", { class: "btn btn-danger disabled" })
    else
      content_tag(:a, "Run Job", { href: admin_run_job_path(job), data: { remote: true }, class: "btn btn-success" })
    end
  end
      
  
end
