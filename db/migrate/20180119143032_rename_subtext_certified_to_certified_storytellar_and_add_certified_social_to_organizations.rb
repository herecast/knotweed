class RenameSubtextCertifiedToCertifiedStorytellarAndAddCertifiedSocialToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :certified_social, :boolean, default: false
    rename_column :organizations, :subtext_certified, :certified_storyteller
  end
end
