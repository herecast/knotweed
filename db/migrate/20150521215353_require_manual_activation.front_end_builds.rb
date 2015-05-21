# This migration comes from front_end_builds (originally 20150114202950)
class RequireManualActivation < ActiveRecord::Migration
  def change
    add_column :front_end_builds_apps,
      :require_manual_activation,
      :boolean,
      default: false
  end
end
