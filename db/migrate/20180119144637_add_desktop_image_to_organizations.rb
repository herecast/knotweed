class AddDesktopImageToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :desktop_image, :string
  end
end
