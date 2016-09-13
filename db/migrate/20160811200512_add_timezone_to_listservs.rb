class AddTimezoneToListservs < ActiveRecord::Migration
  def change
    add_column :listservs, :timezone, :string, default: "Eastern Time (US & Canada)"
  end
end
