class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer :created_by_id
      t.string :controller
      t.string :action
      t.datetime :start_date
      t.datetime :end_date
      t.text :content

      t.timestamps
    end
  end
end
