class CreateConsumerAppsPublicationsJoinTable < ActiveRecord::Migration
  def change
    create_table :consumer_apps_publications, id: false do |t|
      t.integer :consumer_app_id, null: false
      t.integer :publication_id, null: false
    end
    add_index :consumer_apps_publications, [:consumer_app_id, :publication_id], name: :consumer_app_publication_index
  end
end
