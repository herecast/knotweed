class AddEmbeddedAdsToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :embedded_ad, :boolean, default: false
  end
end
