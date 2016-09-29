class AddProfileImageToOrgs < ActiveRecord::Migration
  def change
    add_column :organizations, :profile_image, :string, limit: 255
    add_column :organizations, :background_image, :string, limit: 255
  end
end
