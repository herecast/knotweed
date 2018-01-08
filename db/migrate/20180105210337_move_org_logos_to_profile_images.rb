class MoveOrgLogosToProfileImages < ActiveRecord::Migration
  def up
    execute "update organizations set profile_image = logo where logo is not null and logo != '' and profile_image is null"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
