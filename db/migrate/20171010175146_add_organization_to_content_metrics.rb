class AddOrganizationToContentMetrics < ActiveRecord::Migration
  def change
    change_table :content_metrics do |t|
      t.references :organization, index: true
    end
  end
end
