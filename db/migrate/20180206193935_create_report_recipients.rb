class CreateReportRecipients < ActiveRecord::Migration
  def change
    create_table :report_recipients do |t|
      t.integer :report_id
      t.integer :user_id
      t.string :alternative_emails
      t.integer :created_by
      t.integer :updated_by

      t.timestamps null: false
    end
  end
end
