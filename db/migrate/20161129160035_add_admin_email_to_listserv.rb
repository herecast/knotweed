class AddAdminEmailToListserv < ActiveRecord::Migration
  def change
    add_column :listservs, :admin_email, :string
  end
end
