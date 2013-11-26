class ChangeImageToBeLongerOnContents < ActiveRecord::Migration
  def up
    change_column :contents, :image, :string, limit: 400
  end

  def down
    change_column :contents, :image, :string, limit: 255
  end
end
