class AddDefaultValueToTestGroupUsers < ActiveRecord::Migration
  def up
    change_column_default :users, :test_group, 'consumer'
  end

  def down
    change_column_default :users, :test_group, nil
  end
end
