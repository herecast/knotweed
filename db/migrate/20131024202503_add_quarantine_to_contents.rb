class AddQuarantineToContents < ActiveRecord::Migration
  def change
    add_column :contents, :quarantine, :boolean, default: false
  end
end
