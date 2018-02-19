class AddLatestActivityToContents < ActiveRecord::Migration
  def change
    add_column :contents, :latest_activity, :datetime
    execute "UPDATE contents SET latest_activity=updated_at"
  end
end
