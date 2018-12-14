class RemoveListservContentAndListservContentMetrics < ActiveRecord::Migration
  def up
    drop_table :listserv_contents
    drop_table :listserv_content_metrics
    remove_column :listserv_digests, :listserv_content_ids
    remove_column :promotion_listservs, :listserv_content_id
  end

  def down
    add_column :listserv_digests, :listserv_content_ids, :integer, array: true
    add_column :promotion_listservs, :listserv_content_id, :integer

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
      t.string :verify_ip
      t.datetime :deleted_at, index: true
      t.string :deleted_by

      t.timestamps null: false
    end

    create_table :listserv_content_metrics do |t|
      t.integer :listserv_content_id, index: true
      t.string :email
      t.datetime :time_sent
      t.string :post_type
      t.string :username
      t.boolean :verified
      t.boolean :enhanced
      t.boolean :enhance_link_clicked, default: false
      t.string :step_reached

      t.timestamps null: false
    end
  end
end
