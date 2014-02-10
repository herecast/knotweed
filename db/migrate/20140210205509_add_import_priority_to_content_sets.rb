class AddImportPriorityToContentSets < ActiveRecord::Migration
  def change
    add_column :content_sets, :import_priority, :integer, default: 1
  end
end
