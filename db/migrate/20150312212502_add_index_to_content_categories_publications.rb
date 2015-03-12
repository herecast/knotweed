class AddIndexToContentCategoriesPublications < ActiveRecord::Migration
  def change
    add_index :content_categories_publications, [:content_category_id, :publication_id], :name => 'index_on_content_category_id_and_publication_id'
  end
end
