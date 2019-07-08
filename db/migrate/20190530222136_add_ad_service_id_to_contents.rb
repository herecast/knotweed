class AddAdServiceIdToContents < ActiveRecord::Migration[5.1]
  def change
    add_column :contents, :ad_service_id, :string
    add_index :contents, :ad_service_id
  end
end
