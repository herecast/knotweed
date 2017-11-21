class AddSubtextCertifiedToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :subtext_certified, :boolean, default: false
  end
end
