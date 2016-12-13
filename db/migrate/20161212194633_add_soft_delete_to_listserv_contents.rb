class AddSoftDeleteToListservContents < ActiveRecord::Migration
  def change
    change_table :listserv_contents do |t|
      t.datetime :deleted_at
      t.string :deleted_by
    end

    add_index :listserv_contents, :deleted_at
  end
end
