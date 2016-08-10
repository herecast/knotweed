class AddDefaultValueToOrganizationsPayRateInCents < ActiveRecord::Migration
  def up
    change_column :organizations, :pay_rate_in_cents, :integer, default: 0, limit: 8
    Organization.all.each { |o| o.update_attribute(:pay_rate_in_cents, 0) unless o.pay_rate_in_cents.present? }
  end

  def down
  end
end
