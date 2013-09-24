class CreateParameters < ActiveRecord::Migration
  def change
    create_table :parameters do |t|
      t.integer :parser_id
      t.string :name

      t.timestamps
    end
  end
end
