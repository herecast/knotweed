# == Schema Information
#
# Table name: import_records
#
#  id             :integer          not null, primary key
#  import_job_id  :integer
#  items_imported :integer          default(0)
#  failures       :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class ImportRecord < ActiveRecord::Base
  belongs_to :import_job
  has_many :contents, dependent: :destroy
  attr_accessible :failures, :import_job_id, :items_imported

  def log_file
    Logger.new("#{Rails.root}/log/import_records/#{id}.log")
  end

  def job
    import_job
  end
end
