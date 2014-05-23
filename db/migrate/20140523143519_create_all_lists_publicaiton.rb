class CreateAllListsPublicaiton < ActiveRecord::Migration
  def up
    Publication.find_or_create_by_name("All Lists")
  end

  def down
    Publication.find_by_name("All Lists").destroy
  end
end
