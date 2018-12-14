# frozen_string_literal: true

class RemoveMessages < ActiveRecord::Migration
  def up
    drop_table :consumer_apps_messages
    drop_table :messages
  end

  def down
    create_table :messages do |t|
      t.integer :created_by_id
      t.string :controller
      t.string :action
      t.datetime :start_date
      t.datetime :end_date
      t.text :content

      t.timestamps
    end

    create_table :consumer_apps_messages, id: false do |t|
      t.integer :message_id
      t.integer :consumer_app_id
    end
    add_index :consumer_apps_messages, %i[consumer_app_id message_id], unique: true, name: 'consumer_apps_messages_joins_index'
  end
end
