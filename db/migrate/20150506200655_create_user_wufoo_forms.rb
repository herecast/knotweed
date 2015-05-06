class CreateUserWufooForms < ActiveRecord::Migration
  def change
    create_table :user_wufoo_forms, id: false do |t|
      t.integer :user_id
      t.integer :wufoo_form_id
    end

    add_index :user_wufoo_forms, [:user_id, :wufoo_form_id], unique: true
  end
end
