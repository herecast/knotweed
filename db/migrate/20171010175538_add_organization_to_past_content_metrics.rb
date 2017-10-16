class AddOrganizationToPastContentMetrics < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE content_metrics cm
      SET organization_id = c.organization_id
      FROM contents c
      WHERE c.id = cm.content_id
    SQL
  end

  def down
  end
end
