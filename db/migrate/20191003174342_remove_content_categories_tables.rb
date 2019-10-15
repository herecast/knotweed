class RemoveContentCategoriesTables < ActiveRecord::Migration[5.1]
  def change
    remove_column :contents, :root_content_category_id, :integer 

    drop_table :content_categories_organizations, id: false do |t|
      t.bigint 'content_category_id'
      t.bigint 'organization_id'
      t.index %w[content_category_id organization_id], name: 'idx_16559_index_on_content_category_id_and_publication_id', using: :btree
    end

    drop_table :content_categories do |t|
      t.string   'name'
      t.bigint   'parent_id'
      t.boolean  'active', default: true
      t.timestamps
    end
  end
end
