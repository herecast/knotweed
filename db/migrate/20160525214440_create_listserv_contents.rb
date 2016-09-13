class CreateListservContents < ActiveRecord::Migration
  def change
    create_table :listserv_contents do |t|
      t.references :listserv, index: true, foreign_key: true
      t.string :sender_name
      t.string :sender_email
      t.string :subject
      t.text :body
      t.references :content_category, index: true, foreign_key: true
      t.references :subscription, index: true, foreign_key: true
      t.string :key, index: true
      t.datetime :verification_email_sent_at
      t.datetime :verified_at
      t.datetime :pubdate
      t.references :content, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
