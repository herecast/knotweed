class AddListTypeToListserv < ActiveRecord::Migration
  def change
    add_column :listservs, :list_type, :string, default: 'custom_list'
  end
end
