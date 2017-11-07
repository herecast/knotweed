class SetLocationConfirmedFalseForSelectTowns < ActiveRecord::Migration
  def change
    execute "UPDATE users SET location_confirmed=FALSE WHERE location_id IN (48,133,116)"
  end
end
