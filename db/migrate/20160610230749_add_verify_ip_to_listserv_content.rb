class AddVerifyIpToListservContent < ActiveRecord::Migration
  def change
    change_table :listserv_contents do |t|
      t.string :verify_ip
    end
  end
end
