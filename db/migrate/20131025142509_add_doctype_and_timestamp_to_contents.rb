class AddDoctypeAndTimestampToContents < ActiveRecord::Migration
  def change
    add_column :contents, :doctype, :string
    add_column :contents, :timestamp, :datetime
  end
end
