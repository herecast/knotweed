class CreateOrganizationContentTags < ActiveRecord::Migration
  def change
    create_table :organization_content_tags do |t|
      t.references :organization, index: true, foreign_key: true
      t.references :content, index: true, foreign_key: true
    end
  end
end
