class AddSubscribeEmailToListservs < ActiveRecord::Migration
  def change
    change_table :listservs do |t|
      t.string :subscribe_email, index: true
    end
  end
end
