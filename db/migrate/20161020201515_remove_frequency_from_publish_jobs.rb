class RemoveFrequencyFromPublishJobs < ActiveRecord::Migration
  def change
    remove_column :publish_jobs, :frequency
  end
end
