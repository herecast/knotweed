class AddFilteredToImportRecords < ActiveRecord::Migration
  def change
    add_column :import_records, :filtered, :integer, default: 0
  end
end
