class AddPublishedFlagToContents < ActiveRecord::Migration
  def up
    add_column :contents, :published, :boolean, default: false
    add_index :contents, :published

    # update flag for all contents published to "production" repo
    # this is dramatically faster to do with straight SQL than with rails...hence:
    Content.joins("INNER JOIN contents_repositories ON contents_repositories.content_id = contents.id ")
      .where("contents_repositories.repository_id = ?", Repository::PRODUCTION_REPOSITORY_ID)
      .update_all(published: true)
  end

  def down
    remove_column :contents, :published
  end
end
