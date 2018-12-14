# frozen_string_literal: true

class DropContentLocationsTable < ActiveRecord::Migration[4.2]
  def up
    drop_table :content_locations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
