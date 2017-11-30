class RemovePayRateInCentsFromOrganizations < ActiveRecord::Migration
  def up
    remove_column :organizations, :pay_rate_in_cents, :integer
  end

  def down
    add_column :organizations, :pay_rate_in_cents, :integer
  end
end
