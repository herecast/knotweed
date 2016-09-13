class ChangeReceivedEmailResultToText < ActiveRecord::Migration
  def change
    change_column :received_emails, :result, :text
  end
end
