class AddPromoteRadiusToContent < ActiveRecord::Migration
  def change
    add_column :contents, :promote_radius, :integer, default: nil
  end
end
