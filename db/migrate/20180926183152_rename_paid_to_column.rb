class RenamePaidToColumn < ActiveRecord::Migration
  def up
    rename_column :payments, :paid_to, :paid_to_id
  end

  def down
    rename_column :payments, :paid_to_id, :paid_to
  end
end
