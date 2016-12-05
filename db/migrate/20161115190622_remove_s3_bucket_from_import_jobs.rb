class RemoveS3BucketFromImportJobs < ActiveRecord::Migration
  def change
    remove_column :import_jobs, :s3_bucket
  end
end
