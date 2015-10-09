class AddPrimaryToImages < ActiveRecord::Migration
  def change
    add_column :images, :primary, :boolean
  end
end
