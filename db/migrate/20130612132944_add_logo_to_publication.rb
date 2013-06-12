class AddLogoToPublication < ActiveRecord::Migration
  def change
    add_column :publications, :logo, :string
  end
end
