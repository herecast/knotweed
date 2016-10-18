class SetIsRegionForUpperValley < ActiveRecord::Migration
  def up
    Location.where(city: 'Upper Valley').update_all(is_region: true)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
