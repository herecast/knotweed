class BackPopulateTestGroupInUsers < ActiveRecord::Migration
  def up 
    execute <<-SQL
      UPDATE users SET users.test_group = 'consumer' where users.test_group IS NULL AND users.email NOT LIKE '%subtext%';
    SQL

    execute <<-SQL
      UPDATE users SET users.test_group = 'subtext' where users.email LIKE '%subtext%';
    SQL
  end
end
