class CreateCategoryCorrections < ActiveRecord::Migration
  def change
    create_table :category_corrections do |t|
      t.integer :content_id
      t.string :old_category
      t.string :new_category
      t.string :user_email
      t.string :title
      t.text :content_body

      t.timestamps
    end
  end
end
