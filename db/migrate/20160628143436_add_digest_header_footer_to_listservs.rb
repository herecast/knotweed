class AddDigestHeaderFooterToListservs < ActiveRecord::Migration
  def change
    change_table :listservs do |t|
      t.text :digest_header
      t.text :digest_footer
    end
  end
end
