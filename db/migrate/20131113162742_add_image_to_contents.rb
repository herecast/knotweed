class AddImageToContents < ActiveRecord::Migration
  def change
    add_column :contents, :image, :string
  end
end
