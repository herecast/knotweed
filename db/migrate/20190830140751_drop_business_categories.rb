class DropBusinessCategories < ActiveRecord::Migration[5.1]
  def change
    drop_table :business_categories
    drop_table :business_categories_business_profiles
    drop_table :business_categories_business_categories
  end
end
