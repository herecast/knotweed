class AddEmailColumnsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :alert_recipients, :string
    add_column :reports, :cc_email, :string
    add_column :reports, :bcc_email, :string
  end
end
