# frozen_string_literal: true

class RemoveDatasetsAndDataContexts < ActiveRecord::Migration
  def up
    drop_table :data_contexts
    drop_table :datasets
  end

  def down
    create_table :data_contexts do |t|
      t.string :context
      t.boolean :loaded, default: false
      t.datetime :last_load
      t.boolean :archived, default: false

      t.timestamps
    end

    create_table :datasets do |t|
      t.integer :data_context_id
      t.string :name
      t.string :description
      t.string :realm
      t.string :model_type

      t.timestamps
    end
  end
end
