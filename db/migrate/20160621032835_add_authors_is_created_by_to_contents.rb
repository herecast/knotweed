class AddAuthorsIsCreatedByToContents < ActiveRecord::Migration
  def change
    add_column :contents, :authors_is_created_by, :boolean, default: false
  end
end
