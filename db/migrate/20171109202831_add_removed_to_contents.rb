class AddRemovedToContents < ActiveRecord::Migration
  def change
    add_column :contents, :removed, :boolean, default: false
  end
end
