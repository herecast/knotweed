class CreateOrganizationHides < ActiveRecord::Migration[5.1]
  def change
    create_table :organization_hides do |t|
      t.references :user, foreign_key: true, index: true
      t.references :organization, foreign_key: true, index: true
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
