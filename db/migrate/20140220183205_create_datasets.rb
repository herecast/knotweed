class CreateDatasets < ActiveRecord::Migration
  def change
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
