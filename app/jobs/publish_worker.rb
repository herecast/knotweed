class PublishWorker < ApplicationJob
  queue_as :imports_and_publishing

  after_enqueue do
    publish_job = self.arguments[0]
    publish_job.update sidekiq_jid: self.job_id, status: 'scheduled'
  end

  def perform(publish_job)
    begin
      @publish_job = publish_job
      @publish_job.update_attribute :status, 'running'
      @record = @publish_job.publish_records.create
      if @publish_job.query_params[:repository_id].present?
        repo = Repository.find @publish_job.query_params[:repository_id]
      else
        repo = nil
      end
      Content.contents_query(@publish_job.query_params).find_each(batch_size: 500) do |c|
        @record.contents << c
        c.publish(@publish_job.publish_method, repo, @record)
      end
      log(:info, "failures: #{@record.failures}")
      log(:info, "items published: #{@record.items_published}")
      @publish_job.create_file_archive(@record) unless @record.files.empty?
      @publish_job.update status: 'success', sidekiq_jid: nil
    rescue Exception => e
      log(:error, "Error creating file archive: #{e}\n#{e.backtrace.join("\n")}")
      @publish_job.update status: 'failed'
    end
  end

  private

  def log(log_level, message)
    logger.send(log_level, "[PublishRecord #{@record.try(:id)}] #{message}")
  end
end
