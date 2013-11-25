class CreateContentsPublishRecordsJoinTable < ActiveRecord::Migration
  def change
    create_table :contents_publish_records, :id => false do |t|
      t.integer :content_id
      t.integer :publish_record_id
    end
  end
end
