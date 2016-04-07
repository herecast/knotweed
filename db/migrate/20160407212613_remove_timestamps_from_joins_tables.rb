class RemoveTimestampsFromJoinsTables < ActiveRecord::Migration
  def up
    [:contents_locations, :locations_locations].each do |t|
      execute "ALTER TABLE #{t} MODIFY id INT NOT NULL"
      execute "ALTER TABLE #{t} DROP PRIMARY KEY"
      remove_column t, :id
      remove_column t, :created_at
      remove_column t, :updated_at
    end
  end


  def down
    [:contents_locations, :locations_locations].each do |t|
      execute "ALTER TABLE #{t} ADD id INT PRIMARY KEY AUTO_INCREMENT"
      add_column t, :created_at, :datetime
      add_column t, :updated_at, :datetime
    end
  end
end
