class AddLocationReferenceToContents < ActiveRecord::Migration
  def change
    add_reference :contents, :location, index: true, foreign_key: true
  end
end
