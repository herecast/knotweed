class AddCustomQueryToListserv < ActiveRecord::Migration
  def change
    add_column :listservs, :digest_query, :text
  end
end
