class AddDigestSummaryAndSubjectToListserv < ActiveRecord::Migration
  def change
    change_table :listservs do |t|
      t.string :digest_subject
      t.string :digest_preheader
    end
  end
end
