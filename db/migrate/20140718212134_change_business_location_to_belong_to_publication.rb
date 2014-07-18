class ChangeBusinessLocationToBelongToPublication < ActiveRecord::Migration
  def change
    # better to drop column and re-add rather than rename
    # because the values are meaningless when we switch
    add_column :business_locations, :publication_id, :integer
    remove_column :business_locations, :organization_id
  end
end
