class AddForwardingAddressToListservs < ActiveRecord::Migration
  def change
    add_column :listservs, :forwarding_email, :string
  end
end
