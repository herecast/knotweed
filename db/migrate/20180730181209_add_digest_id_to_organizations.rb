class AddDigestIdToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :digest_id, :integer
  end
end
