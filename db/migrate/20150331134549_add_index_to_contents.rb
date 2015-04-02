class AddIndexToContents < ActiveRecord::Migration
  def change
    add_index :contents, :authoremail
  end
end
