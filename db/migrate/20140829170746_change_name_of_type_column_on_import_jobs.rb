class ChangeNameOfTypeColumnOnImportJobs < ActiveRecord::Migration
  def up
    rename_column :import_jobs, :type, :job_type
    # set all existing jobs to appropriate job type
    ImportJob.each do |ij|
      if ij.frequency > 0
        ij.update_attribute :job_type, ImportJob::RECURRING
      else
        ij.update_attribute :job_type, ImportJob::AD_HOC
      end
    end
  end

  def down
    rename_column :import_jobs, :job_type, :type
  end
end
