class AddIndexToPublicationsOnNames < ActiveRecord::Migration
  def change
    add_index :publications, :name, unique: true
  end
end
