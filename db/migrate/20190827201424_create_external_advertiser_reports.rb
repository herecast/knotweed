class CreateExternalAdvertiserReports < ActiveRecord::Migration[5.1]
  def change
    create_table :external_advertiser_reports do |t|
      t.string :title
      t.string :pdf
      t.references :organization, foreign_key: true

      t.timestamps
    end
  end
end
