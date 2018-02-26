class AddEmailSubjectToReports < ActiveRecord::Migration
  def change
    add_column :reports, :email_subject, :string
  end
end
