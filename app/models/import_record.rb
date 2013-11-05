class ImportRecord < ActiveRecord::Base
  belongs_to :import_job
  has_many :contents
  attr_accessible :failures, :import_job_id, :items_imported
end
