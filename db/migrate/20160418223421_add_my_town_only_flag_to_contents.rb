class AddMyTownOnlyFlagToContents < ActiveRecord::Migration
  def change
    add_column :contents, :my_town_only, :boolean, default: false
  end
end

