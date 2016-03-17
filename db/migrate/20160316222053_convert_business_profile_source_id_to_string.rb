class ConvertBusinessProfileSourceIdToString < ActiveRecord::Migration
  def up
    change_column :business_profiles, :source_id, :string
  end

  def down
    change_column :business_profiles, :source_id, :integer
  end
end
