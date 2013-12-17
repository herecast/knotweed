class ChangeLocationToImportLocation < ActiveRecord::Migration
  def change
    rename_table :locations, :import_locations
    rename_column :contents, :location_id, :import_location_id
    rename_column :issues, :location_id, :import_location_id
  end
end
