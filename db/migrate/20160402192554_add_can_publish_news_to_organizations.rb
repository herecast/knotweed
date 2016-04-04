class AddCanPublishNewsToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :can_publish_news, :boolean, default: false
  end
end
