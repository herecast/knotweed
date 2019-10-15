class AddHandlesToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :handle, :string

    User.find_each do |user|
      if user.organization.present?
        handle = user.organization.handle_for_user
      else
        handle = user.email.split('@')[0]
      end
      user.update_attribute(:handle, handle)
    end
  end
end
