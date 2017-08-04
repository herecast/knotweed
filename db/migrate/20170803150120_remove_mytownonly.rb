class RemoveMytownonly < ActiveRecord::Migration
  def change
    remove_column :contents, :my_town_only
  end
end
