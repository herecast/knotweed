class AddEdgesToAnnotation < ActiveRecord::Migration
  def change
    add_column :annotations, :edges, :text
  end
end
