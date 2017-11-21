class AddCardFlagsToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :contact_card_active, :boolean, default: true
    add_column :organizations, :description_card_active, :boolean, default: true
    add_column :organizations, :hours_card_active, :boolean, default: true
  end
end
