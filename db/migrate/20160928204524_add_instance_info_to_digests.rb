class AddInstanceInfoToDigests < ActiveRecord::Migration
  def change
    change_table :listserv_digests do |t|
      t.string :from_name
      t.string :reply_to
      t.string :subject
      t.string :template
    end
  end
end
