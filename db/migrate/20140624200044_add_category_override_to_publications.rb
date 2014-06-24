class AddCategoryOverrideToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :category_override, :string
  end
end
