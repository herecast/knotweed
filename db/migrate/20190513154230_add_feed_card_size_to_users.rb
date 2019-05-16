class AddFeedCardSizeToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :feed_card_size, :string
  end
end
