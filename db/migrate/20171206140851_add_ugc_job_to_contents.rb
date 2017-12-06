class AddUgcJobToContents < ActiveRecord::Migration
  def change
    change_table :contents do |t|
      t.string :ugc_job, default: nil
    end
  end
end
