class AddContentToOrganizationHides < ActiveRecord::Migration[5.1]
  def change
    add_reference :organization_hides, :content, foreign_key: true, index: true
  end
end
