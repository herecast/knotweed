class AddUserToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_reference :organizations, :user, foreign_key: true
    User.find_each { |u| u.managed_organizations.first&.update_attribute(:user_id, u.id) }
  end
end
