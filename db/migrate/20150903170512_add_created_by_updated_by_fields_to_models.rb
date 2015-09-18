class AddCreatedByUpdatedByFieldsToModels < ActiveRecord::Migration
  def change
    add_column :contents, :created_by, :integer
    add_column :promotions, :created_by, :integer
    add_column :business_locations, :created_by, :integer
    add_column :contents, :updated_by, :integer
    add_column :promotions, :updated_by, :integer
    add_column :business_locations, :updated_by, :integer

    add_index :contents, :created_by
    add_index :promotions, :created_by
    add_index :business_locations, :created_by
  end
end
