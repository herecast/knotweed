class CreateTempUserCaptures < ActiveRecord::Migration
  def change
    create_table :temp_user_captures do |t|
      t.string :name
      t.string :email

      t.timestamps null: false
    end
  end
end
