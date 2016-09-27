class AddDisplaySubscribeToListserv < ActiveRecord::Migration
  def change
    add_column :listservs, :display_subscribe, :boolean, default: false
  end
end
