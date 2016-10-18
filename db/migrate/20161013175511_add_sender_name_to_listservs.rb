class AddSenderNameToListservs < ActiveRecord::Migration
  def change
    add_column :listservs, :sender_name, :string
  end
end
