class AddEventManagerRole < ActiveRecord::Migration
  def up
    Role.create(name: "event_manager")
  end

  def down
    Role.find_by_name("event_manager").destroy
  end
end
