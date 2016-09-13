class AddUnsubcribeAndPostEmailsToListservs < ActiveRecord::Migration
  def change
    change_table :listservs do |t|
      t.string :unsubscribe_email, index: true
      t.string :post_email, index: true
    end
  end
end
