class AddPreheaderToListservDigest < ActiveRecord::Migration
  def change
    add_column :listserv_digests, :preheader, :string
  end
end
