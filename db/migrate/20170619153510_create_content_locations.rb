class CreateContentLocations < ActiveRecord::Migration
  def up
    create_table :content_locations do |t|
      t.references :content, index: true, foreign_key: true
      t.references :location, index: true, foreign_key: true
      t.string :location_type, default: nil

      t.timestamps
    end

    execute '
      INSERT INTO content_locations (content_id, location_id)
      (SELECT cl.content_id, cl.location_id
        FROM contents_locations AS cl
        INNER JOIN contents ON cl.content_id = contents.id
        INNER JOIN locations ON cl.location_id = locations.id)
    '
  end

  def down
    execute 'TRUNCATE contents_locations'
    execute '
      INSERT INTO contents_locations (content_id, location_id)
      (SELECT cl.content_id, cl.location_id
        FROM content_locations AS cl
        INNER JOIN contents ON cl.content_id = contents.id
        INNER JOIN locations ON cl.location_id = locations.id)
    '

    drop_table :content_locations
  end
end
