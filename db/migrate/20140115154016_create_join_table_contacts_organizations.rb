class CreateJoinTableContactsOrganizations < ActiveRecord::Migration
  def change
    create_table :contacts_organizations do |t|
      t.references :contact
      t.references :organization
    end
  end

end
