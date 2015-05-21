# This migration comes from front_end_builds (originally 20150224040537)
class RemoveApiKeyFromApps < ActiveRecord::Migration
  def change
    remove_column :front_end_builds_apps, :api_key
  end
end
