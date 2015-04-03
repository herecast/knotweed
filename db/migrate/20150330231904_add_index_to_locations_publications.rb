class AddIndexToLocationsPublications < ActiveRecord::Migration
  def change
    add_index :locations_publications, :location_id
    add_index :locations_publications, :publication_id
    add_index :locations_publications, [:location_id, :publication_id]
    add_index :locations_publications, [:publication_id, :location_id]
  end
end
