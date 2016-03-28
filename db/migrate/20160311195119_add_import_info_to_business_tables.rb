class AddImportInfoToBusinessTables < ActiveRecord::Migration
  def change
    add_column :business_profiles, :source, :string
    add_column :business_profiles, :source_id, :integer
    add_column :business_profiles, :existence, :decimal, precision: 5, scale: 5
    add_index :business_profiles, [:source, :source_id]
    add_index :business_profiles, :existence

    add_column :business_categories, :source, :string
    add_column :business_categories, :source_id, :integer
    add_index :business_categories, [:source, :source_id]
  end
end
