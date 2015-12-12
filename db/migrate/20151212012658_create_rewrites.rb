class CreateRewrites < ActiveRecord::Migration
  def change
    create_table :rewrites do |t|
      t.string :source
      t.string :destination

      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end
    add_index :rewrites, :created_by
    add_index :rewrites, :updated_at
  end
end
