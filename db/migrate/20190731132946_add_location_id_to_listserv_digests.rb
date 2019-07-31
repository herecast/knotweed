class AddLocationIdToListservDigests < ActiveRecord::Migration[5.1]
  def change
    add_reference :listserv_digests, :location, foreign_key: true
  end
end
