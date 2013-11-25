class CreatePublishRecords < ActiveRecord::Migration
  def change
    create_table :publish_records do |t|
      t.belongs_to :publish_job
      t.integer :items_published, default: 0
      t.integer :failures, default: 0

      t.timestamps
    end
    add_index :publish_records, :publish_job_id
  end
end
