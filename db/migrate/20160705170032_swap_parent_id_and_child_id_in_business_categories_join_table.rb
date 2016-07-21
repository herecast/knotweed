class SwapParentIdAndChildIdInBusinessCategoriesJoinTable < ActiveRecord::Migration
  def up
    execute "ALTER TABLE business_categories_business_categories ADD tmp1 int;"
    execute "ALTER TABLE business_categories_business_categories ADD tmp2 int;"
    execute "UPDATE business_categories_business_categories SET tmp1 = parent_id;"
    execute "UPDATE business_categories_business_categories SET tmp2 = child_id;"
    execute "UPDATE business_categories_business_categories SET child_id = tmp1;"
    execute "UPDATE business_categories_business_categories SET parent_id = tmp2;"
    execute "ALTER TABLE business_categories_business_categories DROP COLUMN tmp1;"
    execute "ALTER TABLE business_categories_business_categories DROP COLUMN tmp2;"
  end


  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
