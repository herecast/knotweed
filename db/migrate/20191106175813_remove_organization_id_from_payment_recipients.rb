class RemoveOrganizationIdFromPaymentRecipients < ActiveRecord::Migration[5.1]
  def change
    remove_column :payment_recipients, :organization_id, :integer
  end
end
