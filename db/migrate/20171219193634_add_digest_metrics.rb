class AddDigestMetrics < ActiveRecord::Migration
  def change
    change_table :promotion_banners do |t|
      t.integer :digest_clicks, default: 0, null: false
      t.integer :digest_opens, default: 0, null: false
      t.integer :digest_emails, default: 0, null: false
      t.datetime :digest_metrics_updated, default: nil
    end

    change_table :listserv_digests do |t|
      t.integer :emails_sent, default: 0, null: false
      t.integer :opens_total, default: 0, null: false
      t.hstore :link_clicks
      t.datetime :last_mc_report
    end
  end
end
