class AddAlternateValuesToContent < ActiveRecord::Migration
  def change
    add_column :contents, :alternate_title, :string
    add_column :contents, :alternate_organization_id, :integer
    add_column :contents, :alternate_authors, :string
    add_column :contents, :alternate_text, :string
    add_column :contents, :alternate_image_url, :string
  end
end
