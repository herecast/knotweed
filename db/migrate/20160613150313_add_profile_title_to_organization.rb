class AddProfileTitleToOrganization < ActiveRecord::Migration
  def change
    change_table :organizations do |t|
      t.string :profile_title
    end
  end
end
