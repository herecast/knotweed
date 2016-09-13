class CreateReceivedEmails < ActiveRecord::Migration
  def change
    create_table :received_emails do |t|
      t.string :file_uri, index: true
      t.string :purpose
      t.datetime :processed_at
      t.string :from
      t.string :to
      t.string :message_id
      t.references :record, polymorphic: true, index: true
      t.string :result

      t.timestamps null: false
    end
  end
end
