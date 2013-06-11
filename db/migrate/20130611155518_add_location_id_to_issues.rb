class AddLocationIdToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :location_id, :integer
  end
end
