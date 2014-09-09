class CreateWufooForms < ActiveRecord::Migration
  def change
    create_table :wufoo_forms do |t|
      t.string :form_hash
      t.string :email_field
      t.string :name
      t.text :call_to_action
      t.string :controller
      t.string :action
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :wufoo_forms, [:controller, :action, :active], unique: true
  end
end
