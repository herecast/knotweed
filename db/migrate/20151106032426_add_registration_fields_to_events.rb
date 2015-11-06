class AddRegistrationFieldsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :registration_deadline, :datetime
    add_column :events, :registration_url, :string
    add_column :events, :registration_phone, :string
    add_column :events, :registration_email, :string
  end
end
