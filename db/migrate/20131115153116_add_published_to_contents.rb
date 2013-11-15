class AddPublishedToContents < ActiveRecord::Migration
  def change
    add_column :contents, :published, :boolean, default: false, null: false
  end
end
