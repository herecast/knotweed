class AddFileArchiveToPublishJobs < ActiveRecord::Migration
  def change
    add_column :publish_jobs, :file_archive, :text
  end
end
