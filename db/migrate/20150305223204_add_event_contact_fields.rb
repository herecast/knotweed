class AddEventContactFields < ActiveRecord::Migration
  def change
    add_column :events, :contact_phone, :string
    add_column :events, :contact_email, :string
    add_column :events, :contact_url, :string
  end
end
