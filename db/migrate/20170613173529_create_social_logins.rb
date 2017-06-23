class CreateSocialLogins < ActiveRecord::Migration
  def change
    create_table :social_logins do |t|
      t.references :user, index: true, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.timestamps null: false
      t.json :extra_info
    end
  end
end
