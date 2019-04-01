# frozen_string_literal: true

class BackpopulatePeriodAdRevForPayments < ActiveRecord::Migration[5.1]
  def up
    [
      ['7/1/2018', '7/31/2018', 8575.29],
      ['8/1/2018', '8/31/2018', 9294.50],
      ['9/1/2018', '9/30/2018', 7293.74],
      ['10/1/2018', '10/31/2018', 7247.84],
      ['11/1/2018', '11/30/2018', 7887.84],
      ['12/1/2018', '12/31/2018', 6819.26]
    ].each do |ad_rev|
      Payment.where(
        period_start: DateTime.parse(ad_rev[0]),
        period_end: DateTime.parse(ad_rev[1])
      ).update_all(period_ad_rev: ad_rev[2])
    end
  end

  def down
    Payment.update_all(period_ad_rev: nil)
  end
end
