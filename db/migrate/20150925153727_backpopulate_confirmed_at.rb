class BackpopulateConfirmedAt < ActiveRecord::Migration
  def up
    execute "UPDATE users SET users.confirmed_at=NOW() WHERE users.sign_in_count > 0 AND users.confirmed_at IS NULL;"
  end
end
