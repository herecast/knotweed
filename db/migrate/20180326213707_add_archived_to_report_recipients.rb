# frozen_string_literal: true

class AddArchivedToReportRecipients < ActiveRecord::Migration
  def change
    add_column :report_recipients, :archived, :boolean, default: false
    add_index :report_recipients, %i[user_id report_id]
  end
end
