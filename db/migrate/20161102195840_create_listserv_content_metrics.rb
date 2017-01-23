class CreateListservContentMetrics < ActiveRecord::Migration
  def change
    create_table :listserv_content_metrics do |t|
      t.integer :listserv_content_id
      t.string :email
      t.datetime :time_sent
      t.string :post_type
      t.string :username
      t.boolean :verified
      t.boolean :enhanced

      t.timestamps null: false
    end
  end
end
