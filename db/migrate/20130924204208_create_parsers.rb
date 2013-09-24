class CreateParsers < ActiveRecord::Migration
  def change
    create_table :parsers do |t|
      t.string :filename
      t.integer :organization_id
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
