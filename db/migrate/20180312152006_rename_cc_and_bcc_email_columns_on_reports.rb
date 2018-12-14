# frozen_string_literal: true

class RenameCcAndBccEmailColumnsOnReports < ActiveRecord::Migration
  def change
    rename_column :reports, :cc_email, :cc_emails
    rename_column :reports, :bcc_email, :bcc_emails
  end
end
