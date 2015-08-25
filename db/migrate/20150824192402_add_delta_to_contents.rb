class AddDeltaToContents < ActiveRecord::Migration
  def change
    add_column :contents, :delta, :boolean, default: true, null: false
  end
end
