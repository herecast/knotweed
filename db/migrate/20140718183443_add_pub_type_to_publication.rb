class AddPubTypeToPublication < ActiveRecord::Migration
  def change
    add_column :publications, :pub_type, :string
    add_column :publications, :display_attributes, :boolean, default: false
  end
end
