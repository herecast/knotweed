class CreateOrganizationLocations < ActiveRecord::Migration
  def up
    create_table :organization_locations do |t|
      t.references :organization, index: true, foreign_key: true
      t.references :location, index: true, foreign_key: true
      t.string :location_type

      t.timestamps
    end

    execute '
      INSERT INTO organization_locations (organization_id, location_id)
      (SELECT ol.organization_id, ol.location_id
        FROM locations_organizations AS ol
        INNER JOIN organizations ON ol.organization_id = organizations.id
        INNER JOIN locations ON ol.location_id = locations.id)
    '
  end

  def down
    execute 'TRUNCATE locations_organizations'
    execute '
      INSERT INTO locations_organizations (organization_id, location_id)
      (SELECT ol.organization_id, ol.location_id
        FROM organization_locations AS ol
        INNER JOIN organizations ON ol.organization_id = organizations.id
        INNER JOIN locations ON ol.location_id = locations.id)
    '

    drop_table :organization_locations
  end
end
