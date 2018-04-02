class RemoveTempUserCaptures < ActiveRecord::Migration
  def up
    drop_table :temp_user_captures
  end
  
  def down
    create_table :temp_user_captures do |t|
      t.string :name
      t.string :email

      t.timestamps null: false
    end
  end
end
