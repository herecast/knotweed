class AddSponsorToListserv < ActiveRecord::Migration
  def change
    add_column :listservs, :sponsored_by, :string
  end
end
