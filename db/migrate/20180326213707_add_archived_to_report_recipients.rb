class AddArchivedToReportRecipients < ActiveRecord::Migration
  def change
    add_column :report_recipients, :archived, :boolean, default: false
    add_index :report_recipients, [:user_id, :report_id]
  end
end
