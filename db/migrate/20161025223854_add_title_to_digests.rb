class AddTitleToDigests < ActiveRecord::Migration
  def change
    change_table :listserv_digests do |t|
      t.string :title
    end
  end
end
