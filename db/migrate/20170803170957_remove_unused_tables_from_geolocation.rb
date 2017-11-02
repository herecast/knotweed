class RemoveUnusedTablesFromGeolocation < ActiveRecord::Migration
  def change
    execute 'drop table if exists "contents_locations"'
    execute 'drop table if exists "locations_organizations"'
    execute 'drop table if exists "temp_locations_orgs"'
  end
end
