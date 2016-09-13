class AddTemplateToListserv < ActiveRecord::Migration
  def change
    add_column :listservs, :template, :string
  end
end
