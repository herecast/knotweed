class BackpopulateListTypeOnListserv < ActiveRecord::Migration
  def up
    Listserv.where.not(reverse_publish_email: nil).update_all({list_type: 'external_list'})
    Listserv.where.not(subscribe_email: nil).update_all({list_type: 'internal_list'})
    Listserv.where(reverse_publish_email: nil).where(subscribe_email: nil).update_all({list_type: 'custom_digest'})
  end

  def down
    raise ActiveRecord::IrreversibleMigrationError
  end
end
