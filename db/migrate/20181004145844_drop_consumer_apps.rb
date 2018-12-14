class DropConsumerApps < ActiveRecord::Migration
  def change
    drop_table :consumer_apps do |t|
      t.string :name
      t.string :uri, index: true
      t.timestamps null: false
    end

    drop_table :consumer_apps_organizations, id: false do |t|
      t.integer :consumer_app_id, null: false
      t.integer :organization_id, null: false
    end
  end
end
