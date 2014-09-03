class AddStopLoopToImportJob < ActiveRecord::Migration
  def change
    add_column :import_jobs, :stop_loop, :boolean, default: true
  end
end
