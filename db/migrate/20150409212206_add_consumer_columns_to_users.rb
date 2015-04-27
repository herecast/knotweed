class AddConsumerColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :nda_agreed_at, :datetime
    add_column :users, :agreed_to_nda, :boolean, default: false
    add_column :users, :admin, :boolean, default:false
    add_column :users, :event_poster, :boolean, default: false
    add_column :users, :contact_phone, :string
    add_column :users, :contact_email, :string
    add_column :users, :contact_url, :string
    add_column :users, :location_id, :integer
    add_column :users, :test_group, :string
    add_column :users, :muted, :boolean, default: false
    add_column :users, :discussion_listserve, :string
    add_column :users, :view_style, :integer
  end
end
