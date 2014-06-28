class CreateContentsRepositoriesJoinTable < ActiveRecord::Migration
  def change
    create_table :contents_repositories do |t|
      t.integer :content_id
      t.integer :repository_id
      t.timestamps
    end
  end
end
