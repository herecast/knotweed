# frozen_string_literal: true

class AddPeriodAdRevToPayments < ActiveRecord::Migration[5.1]
  def change
    add_column :payments, :period_ad_rev, :decimal
  end
end
