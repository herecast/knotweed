class ConvertBusinessProfileSourceIdToString < ActiveRecord::Migration
  def up
    change_column :business_profiles, :source_id, :string
    change_column :business_profiles, :existence, :decimal, precision: 5, scale: 5
  end

  def down
    change_column :business_profiles, :source_id, :integer
    change_column :business_profiles, :existence, :decimal
  end
end
