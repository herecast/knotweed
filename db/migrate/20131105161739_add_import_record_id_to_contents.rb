class AddImportRecordIdToContents < ActiveRecord::Migration
  def change
    add_column :contents, :import_record_id, :integer
  end
end
