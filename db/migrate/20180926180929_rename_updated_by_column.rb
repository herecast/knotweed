class RenameUpdatedByColumn < ActiveRecord::Migration
  def up
    rename_column :contents, :updated_by, :updated_by_id
    rename_column :business_feedbacks, :updated_by, :updated_by_id
    rename_column :business_locations, :updated_by, :updated_by_id
    rename_column :promotions, :updated_by, :updated_by_id
    rename_column :rewrites, :updated_by, :updated_by_id
  end

  def down
    rename_column :contents, :updated_by_id, :updated_by
    rename_column :business_feedbacks, :updated_by_id, :updated_by
    rename_column :business_locations, :updated_by_id, :updated_by
    rename_column :promotions, :updated_by_id, :updated_by
    rename_column :rewrites, :updated_by_id, :updated_by
  end
end
