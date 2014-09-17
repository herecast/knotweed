class AddPageUrlFieldToWufooForms < ActiveRecord::Migration
  def change
    add_column :wufoo_forms, :page_url_field, :string
  end
end
