class AddProfileAdOverrideToOrgs < ActiveRecord::Migration
  def change
    add_column :organizations, :profile_ad_override, :string, limit: 255
  end
end
