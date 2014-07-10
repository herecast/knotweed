class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name
      t.integer :channel_id

      t.timestamps
    end

    add_index :categories, :name

    remove_column :channels, :categories
  end
end
