class SetExistingUsersLocationConfirmedTrue < ActiveRecord::Migration
  def change
    execute "UPDATE users SET location_confirmed=TRUE"
  end
end
