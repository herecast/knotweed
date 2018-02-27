class AddStandardUgcOrgToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :standard_ugc_org, :boolean, default: false
    execute "UPDATE organizations SET standard_ugc_org = 'TRUE' WHERE id = 398"
  end
end
