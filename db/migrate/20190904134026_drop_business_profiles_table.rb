class DropBusinessProfilesTable < ActiveRecord::Migration[5.1]
  def up
    drop_table :business_profiles
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
