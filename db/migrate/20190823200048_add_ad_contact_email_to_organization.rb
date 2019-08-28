class AddAdContactEmailToOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :ad_contact_email, :string
  end
end
