class CreateConsumerApps < ActiveRecord::Migration
  def change
    create_table :consumer_apps do |t|
      t.string :name
      t.string :uri
      t.integer :repository_id

      t.timestamps
    end

    create_table :consumer_apps_wufoo_forms, id: false do |t|
      t.integer :consumer_app_id
      t.integer :wufoo_form_id
    end

    create_table :consumer_apps_messages, id: false do |t|
      t.integer :message_id
      t.integer :consumer_app_id
    end

    add_index :consumer_apps, :uri, unique: true
    add_index :consumer_apps_wufoo_forms, [:consumer_app_id, :wufoo_form_id], unique: true, name: "consumer_apps_wufoo_forms_joins_index"
    add_index :consumer_apps_messages, [:consumer_app_id, :message_id], unique: true, name: "consumer_apps_messages_joins_index"
  end
end
