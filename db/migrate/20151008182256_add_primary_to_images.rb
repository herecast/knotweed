class AddPrimaryToImages < ActiveRecord::Migration
  def change
    add_column :images, :primary, :boolean, default: false
  end
end
