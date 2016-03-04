class CreateBusinessCategories < ActiveRecord::Migration
  def change
    create_table :business_categories do |t|
      t.string :name
      t.string :description
      t.string :icon_class
      t.timestamps
    end

    create_table :business_categories_business_categories, id: false do |t|
      t.integer :parent_id
      t.integer :child_id
    end

    add_index :business_categories_business_categories, [:parent_id, :child_id],
      unique: true, name: 'business_categories_index'

    create_table :business_categories_business_profiles, id: false do |t|
      t.integer :business_category_id
      t.integer :business_profile_id
    end
  end
end
