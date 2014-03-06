class AddFieldsToAnnotations < ActiveRecord::Migration
  def change
    add_column :annotations, :is_trusted, :boolean
    add_column :annotations, :rule, :string
  end
end
