class CreateSignInTokens < ActiveRecord::Migration
  def change
    create_table :sign_in_tokens do |t|
      t.string :token, index: true, null: false, unique: true
      t.references :user, index: true, foreign_key: true
      t.datetime :created_at, null: false
    end
  end
end
