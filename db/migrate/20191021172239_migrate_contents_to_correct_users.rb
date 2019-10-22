class MigrateContentsToCorrectUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :contents, :former_created_by_id, :integer
    Content.joins(:organization).where.not(organization_id: 398).where('contents.created_by_id != organizations.user_id').each do |content|
      organization = content.organization

      former_created_by_id = content.created_by_id
      content.update_attributes(
        created_by_id: organization.user_id,
        former_created_by_id: former_created_by_id
      )
    end
  end
end
