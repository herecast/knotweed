class AddPublisherAgreementFlagsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :publisher_agreement_confirmed, :boolean, default: false
    add_column :users, :publisher_agreement_confirmed_at, :datetime
    add_column :users, :publisher_agreement_version, :string
  end
end
