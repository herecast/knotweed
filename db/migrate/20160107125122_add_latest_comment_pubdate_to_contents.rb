class AddLatestCommentPubdateToContents < ActiveRecord::Migration
  def up
    add_column :contents, :latest_comment_pubdate, :datetime
    # NOTE: there's a rake task called backpopulate:latest_comment_pubdates
    # that should update latest_comment_pubdates for all existing parent comments
    # after running this migration, call it with:
    #
    #   rake backpopulate:latest_comment_updates
    #
    add_column :contents, :root_parent_id, :integer
  end

  def down
    remove_column :contents, :latest_comment_pubdate
    remove_column :contents, :root_parent_id
  end
end
