class CreateDataContexts < ActiveRecord::Migration
  def change
    create_table :data_contexts do |t|
      t.string :context
      t.boolean :loaded, default: false
      t.datetime :last_load
      t.boolean :archived, default: false

      t.timestamps
    end
  end
end
