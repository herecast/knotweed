class CreateListservs < ActiveRecord::Migration
  def change
    create_table :listservs do |t|
      t.string :name
      t.string :reverse_publish_email
      t.string :import_name
      t.boolean :active

      t.timestamps
    end
  end
end
