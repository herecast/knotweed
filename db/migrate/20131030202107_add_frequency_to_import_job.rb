class AddFrequencyToImportJob < ActiveRecord::Migration
  def change
    add_column :import_jobs, :frequency, :integer, default: 0
  end
end
