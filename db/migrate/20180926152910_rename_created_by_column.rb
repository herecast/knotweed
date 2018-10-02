class RenameCreatedByColumn < ActiveRecord::Migration
  def up
    rename_column :contents, :created_by, :created_by_id
    rename_column :business_feedbacks, :created_by, :created_by_id
    rename_column :business_locations, :created_by, :created_by_id
    rename_column :promotions, :created_by, :created_by_id
    rename_column :rewrites, :created_by, :created_by_id
  end

  def down
    rename_column :contents, :created_by_id, :created_by
    rename_column :business_feedbacks, :created_by_id, :created_by
    rename_column :business_locations, :created_by_id, :created_by
    rename_column :promotions, :created_by_id, :created_by
    rename_column :rewrites, :created_by_id, :created_by
  end
end
