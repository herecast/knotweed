class AddFileTypeToImages < ActiveRecord::Migration
  def change
    add_column :images, :file_extension, :string
  end
end
