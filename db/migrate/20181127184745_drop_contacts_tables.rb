class DropContactsTables < ActiveRecord::Migration[5.1]
  def change
    drop_table :contacts do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.text :notes
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :contact_type
      t.text :address
    end

    drop_table :contacts_organizations, id: false do |t|
      t.integer :contact_id
      t.integer :organization_id
    end
  end
end
