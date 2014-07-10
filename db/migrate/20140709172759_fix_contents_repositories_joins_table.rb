class FixContentsRepositoriesJoinsTable < ActiveRecord::Migration
  def up
    drop_table :contents_repositories
    create_table :contents_repositories, id: false do |t|
      t.integer :content_id, null: false
      t.integer :repository_id, null: false
    end
    add_index :contents_repositories, [:content_id, :repository_id]
  end

  def down
    drop_table :contents_repositories
    create_table :contents_repositories do |t|
      t.integer :content_id
      t.integer :repository_id
      t.timestamps
    end
  end
end
