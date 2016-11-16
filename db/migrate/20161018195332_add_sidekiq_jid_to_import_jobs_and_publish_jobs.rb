class AddSidekiqJidToImportJobsAndPublishJobs < ActiveRecord::Migration
  def change
    [:import_jobs, :publish_jobs].each do |t|
      add_column t, :sidekiq_jid, :string
      add_column t, :next_scheduled_run, :datetime
    end
  end
end
