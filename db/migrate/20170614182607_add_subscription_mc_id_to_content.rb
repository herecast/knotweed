class AddSubscriptionMcIdToContent < ActiveRecord::Migration
  def change
    add_column :contents, :subscriber_mc_identifier, :string
  end
end
