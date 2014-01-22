class AddDeveloperNotesToContentSets < ActiveRecord::Migration
  def change
    add_column :content_sets, :developer_notes, :text
  end
end
