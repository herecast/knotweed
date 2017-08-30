class AddAdSalesAgentAndAdContactNicknameAndAdContactFullnameToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :ad_sales_agent, :string
    add_column :organizations, :ad_contact_nickname, :string
    add_column :organizations, :ad_contact_fullname, :string
  end
end
