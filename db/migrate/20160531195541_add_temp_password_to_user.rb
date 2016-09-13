class AddTempPasswordToUser < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :temp_password
    end
  end
end
