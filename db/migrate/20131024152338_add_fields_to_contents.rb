class AddFieldsToContents < ActiveRecord::Migration
  def change
    add_column :contents, :copyright, :string
    add_column :contents, :guid, :string
    add_column :contents, :pubdate, :datetime
    add_column :contents, :categories, :string
    add_column :contents, :topics, :string
    add_column :contents, :summary, :text
    add_column :contents, :url, :string
    add_column :contents, :origin, :string
    add_column :contents, :mimetype, :string
    add_column :contents, :language, :string
    add_column :contents, :page, :string
    add_column :contents, :wordcount, :string
    add_column :contents, :authoremail, :string
    add_column :contents, :contentsource_id, :integer
    add_column :contents, :file, :string
    remove_column :contents, :subject

  end
end
