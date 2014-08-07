class AddFeaturedFlagToContents < ActiveRecord::Migration
  def change
    add_column :contents, :featured, :boolean, default: false
  end
end
