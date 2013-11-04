class AddContactsToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :admin_contact_id, :integer
    add_column :publications, :tech_contact_id, :integer
    add_column :publications, :website, :string
    add_column :publications, :publishing_frequency, :string
    add_column :publications, :notes, :text
  end
end
