class RemoveAlternativeEmailsFromPaymentRecipients < ActiveRecord::Migration
  def change
    remove_column :payment_recipients, :alternative_emails, :string
  end
end
