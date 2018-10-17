class DropContentLocationsTable < ActiveRecord::Migration
  def up
    drop_table :content_locations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
