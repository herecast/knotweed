class AddPreheaderToCampaign < ActiveRecord::Migration
  def change
    add_column :campaigns, :preheader, :string
  end
end
