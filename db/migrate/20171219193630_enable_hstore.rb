class EnableHstore < ActiveRecord::Migration
  disable_ddl_transaction!
  def up

    begin
      execute "CREATE EXTENSION IF NOT EXISTS hstore"
    rescue
      # it's okay! prod needs to have this done manually
      puts "Your postgresql environment requires a super user to enable the hstore extension!"
    end
  end

  def down
    raise ActiveRecord::IrreversableMigration
  end
end
