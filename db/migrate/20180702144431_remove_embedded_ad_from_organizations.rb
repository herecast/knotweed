class RemoveEmbeddedAdFromOrganizations < ActiveRecord::Migration
  def change
    remove_column :organizations, :embedded_ad, :boolean
  end
end