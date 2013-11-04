class ImportRecord < ActiveRecord::Base
  belongs_to :import_job
  attr_accessible :failures, :import_job_id, :items_imported
end
