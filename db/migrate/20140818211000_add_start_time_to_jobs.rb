class AddStartTimeToJobs < ActiveRecord::Migration
  def change
    add_column :publish_jobs, :run_at, :datetime
    add_column :import_jobs, :run_at, :datetime
  end
end
