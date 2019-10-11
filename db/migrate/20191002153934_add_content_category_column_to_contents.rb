class AddContentCategoryColumnToContents < ActiveRecord::Migration[5.1]
  def change
    add_column :contents, :content_category, :string
    remove_column :contents, :content_category_id, :integer
    add_index :contents, :content_category

    # set content_category based on root_content_category
    reversible do |dir|
      dir.up do
        execute  <<-SQL
UPDATE contents
SET content_category = (
  CASE content_categories.name
      WHEN 'news' THEN 'news'
      WHEN 'local news' THEN 'news'
      WHEN 'market' THEN 'market'
      WHEN 'event' THEN 'event'
      WHEN 'campaign' THEN 'campaign'
      ELSE 'talk_of_the_town'
    END
  )
FROM content_categories
WHERE contents.root_content_category_id = content_categories.id
        SQL
      end
      dir.down { }
    end
  end
end
