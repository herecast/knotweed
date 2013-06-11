class CreateContents < ActiveRecord::Migration
  def change
    create_table :contents do |t|
      t.string :title
      t.string :subtitle
      t.string :authors
      t.string :subject
      t.text :content
      t.integer :issue_id
      t.integer :location_id

      t.timestamps
    end
  end
end
