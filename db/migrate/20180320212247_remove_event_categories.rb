# frozen_string_literal: true

class RemoveEventCategories < ActiveRecord::Migration
  def up
    drop_table :event_categories
  end

  def down
    create_table :event_categories do |t|
      t.string :name
      t.string :query
      t.string :query_modifier

      t.timestamps null: false
    end
  end
end
