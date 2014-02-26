class AddDetailsToAnnotations < ActiveRecord::Migration
  def change
    add_column :annotations, :startnode, :string
    add_column :annotations, :endnode, :string
    add_column :annotations, :type, :string
    add_column :annotations, :is_generated, :boolean
    add_column :annotations, :lookup_class, :string
    add_column :annotations, :token_feature, :string
    add_column :annotations, :recognized_class, :string
    add_column :annotations, :annotated_string, :string
    add_column :annotations, :instance, :string
  end
end
