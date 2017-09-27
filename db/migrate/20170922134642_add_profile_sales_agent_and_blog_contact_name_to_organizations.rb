class AddProfileSalesAgentAndBlogContactNameToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :profile_sales_agent, :string
    add_column :organizations, :blog_contact_name, :string
  end
end
