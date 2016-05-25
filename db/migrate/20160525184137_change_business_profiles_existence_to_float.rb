class ChangeBusinessProfilesExistenceToFloat < ActiveRecord::Migration
  def up
    change_column :business_profiles, :existence, :float
  end

  def down
    change_column :business_profiles, :existence, :decimal, precision: 5, scale: 5
  end
end
