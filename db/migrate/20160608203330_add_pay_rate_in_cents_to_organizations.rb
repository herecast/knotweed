class AddPayRateInCentsToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :pay_rate_in_cents, :integer
  end
end
