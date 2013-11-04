class AddFieldsToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :type, :string
    add_column :organizations, :notes, :text
  end
end
