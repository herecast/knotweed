class CreateJoinTableContactsPublications < ActiveRecord::Migration
  def up
    create_table :contacts_publications do |t|
      t.integer :contact_id
      t.integer :publication_id
      t.timestamps
    end

    remove_column :publications, :admin_contact_id
    remove_column :publications, :tech_contact_id
    add_column :contacts, :contact_type, :string
  end

  def down
    drop_table :contacts_publications
    add_column :publications, :admin_contact_id, :integer
    add_column :publications, :tech_contact_id, :integer
    remove_column :contacts, :contact_type
  end
end
