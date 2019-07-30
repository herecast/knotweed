class RemoveCustomDigestRelatedColumns < ActiveRecord::Migration[5.1]
  def change
    drop_table :promotion_listservs do |t|
      t.reference :listserv_id 
      t.datetime :sent_at
      t.timestamps
    end
    
    remove_column :listservs, :list_type, :string, default: 'custom_list'
    remove_column :listservs, :reverse_publish_email, :string
    remove_column :listservs, :digest_query, :text
    remove_column :campaigns, :digest_query, :text
  end
end
