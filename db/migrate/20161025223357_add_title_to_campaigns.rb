class AddTitleToCampaigns < ActiveRecord::Migration
  def change
    change_table :campaigns do |t|
      t.string :title
    end
  end
end
