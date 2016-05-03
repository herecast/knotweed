class AddArchivedToBusinessProfiles < ActiveRecord::Migration
  def change
    add_column :business_profiles, :archived, :boolean, default: false
  end
end
