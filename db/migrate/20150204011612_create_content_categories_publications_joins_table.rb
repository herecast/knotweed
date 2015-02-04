class CreateContentCategoriesPublicationsJoinsTable < ActiveRecord::Migration
  def change
    create_table :content_categories_publications, id: false do |t|
      t.belongs_to :content_category, index: true
      t.belongs_to :publication, index: true
    end
  end
end
