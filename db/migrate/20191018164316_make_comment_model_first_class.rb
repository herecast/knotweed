class MakeCommentModelFirstClass < ActiveRecord::Migration[5.1]
  def change
    change_table :comments do |t|
      t.text :raw_content
      t.datetime :pubdate
      t.datetime :deleted_at
      t.belongs_to :content
      t.belongs_to :location
      t.belongs_to :created_by, foreign_key: false
      t.belongs_to :updated_by, foreign_key: false
    end

    # needed so that we can destroy the orphaned comment bookmarks through rails callback
    remove_foreign_key :user_bookmarks, :contents

    reversible do |dir|
      dir.up do
        Comment.find_each do |comment|
          old = Content.find_by(channel_type: 'Comment', channel_id: comment.id)
          if old.present?
            comment.update raw_content: old.raw_content,
              pubdate: old.pubdate,
              deleted_at: old.deleted_at,
              location_id: old.location_id,
              content_id: old.root_parent_id,
              created_by_id: old.created_by_id,
              updated_by_id: old.updated_by_id
          else
            comment.destroy # if it has no content attached, destroy it
          end
        end
        Content.where(channel_type: 'Comment').destroy_all
      end
      dir.down { }
    end
  end
end
