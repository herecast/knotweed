class AddSkipAnalyticsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :skip_analytics, :boolean, default: false
  end
end
