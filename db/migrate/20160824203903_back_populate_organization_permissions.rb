class BackPopulateOrganizationPermissions < ActiveRecord::Migration
  def up
    Organization.where(org_type: ['Publication', 'Publisher', 'Blog']).update_all({can_publish_news: true})
  end

  def down
    raise ActiveRecord::IrreversibleMigrationError
  end
end
