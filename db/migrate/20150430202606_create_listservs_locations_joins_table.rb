class CreateListservsLocationsJoinsTable < ActiveRecord::Migration
  def change
    create_table :listservs_locations, id: false do |t|
      t.belongs_to :listserv, index: true
      t.belongs_to :location, index: true
    end
  end
end
