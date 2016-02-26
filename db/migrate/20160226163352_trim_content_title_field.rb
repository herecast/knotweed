class TrimContentTitleField < ActiveRecord::Migration
  def up
    execute <<-SQL
      update contents set title=TRIM(title)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
