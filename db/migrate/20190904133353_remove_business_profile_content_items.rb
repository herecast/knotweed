class RemoveBusinessProfileContentItems < ActiveRecord::Migration[5.1]
  def up
    Content.where(channel_type: 'BusinessProfile').destroy_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
