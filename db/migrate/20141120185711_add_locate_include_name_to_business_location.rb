class AddLocateIncludeNameToBusinessLocation < ActiveRecord::Migration
  def change
    add_column :business_locations, :locate_include_name, :boolean, default: false
  end
end
