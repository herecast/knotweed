class AddEventContactFields < ActiveRecord::Migration
  def up
    add_column :events, :contact_phone, :string
    add_column :events, :contact_email, :string
    add_column :events, :contact_url, :string
  end

  def down
    remove_column :events, :contact_phone
    remove_column :events, :contact_email
    remove_column :events, :contact_url
  end
end
