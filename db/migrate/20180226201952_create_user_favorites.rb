class CreateUserFavorites < ActiveRecord::Migration
  def change
    create_table :user_favorites do |t|
      t.references :user, index: true, foreign_key: true
      t.references :content, index: true, foreign_key: true
      t.integer :event_instance_id

      t.timestamps null: false
    end
  end
end
