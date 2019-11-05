# frozen_string_literal: true
# == Schema Information
#
# Table name: comments
#
#  id            :bigint(8)        not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  raw_content   :text
#  pubdate       :datetime
#  content_id    :bigint(8)
#  location_id   :bigint(8)
#  created_by_id :bigint(8)
#  updated_by_id :bigint(8)
#
# Indexes
#
#  index_comments_on_content_id     (content_id)
#  index_comments_on_created_by_id  (created_by_id)
#  index_comments_on_location_id    (location_id)
#  index_comments_on_updated_by_id  (updated_by_id)
#

class Comment < ActiveRecord::Base
  include Auditable

  has_one :source, through: :content, class_name: 'Organization', foreign_key: 'organization_id'

  belongs_to :content
  belongs_to :location

  scope :not_deleted, -> { where(deleted_at: nil) }

  after_create :increase_comment_stats

  after_commit do
    # the point of this is to update the latest_activity in the search index
    content.try(:reindex, mode: :async)
  end

  def increase_comment_stats
    unless content.blank?
      updates = { comment_count: content.comment_count + 1 }
      updates[:latest_activity] = Time.current if should_update_latest_activity?
      unless Comment.where('content_id = ? and created_by_id = ? and id != ?',
          content_id, created_by_id, id).exists?
        updates[:commenter_count] = content.commenter_count + 1
      end
      content.update updates
    end
  end

  def decrease_comment_stats
    unless content.blank?
      updates = { comment_count: content.comment_count - 1 }
      unless Comment.where('content_id = ? and created_by_id = ? and id != ?',
          content.id, created_by, id).exists?
        new_commenter_count = content.commenter_count - 1
        updates[:commenter_count] = content.commenter_count - 1
      end
      content.update updates
    end
  end

  def sanitized_content
    UgcSanitizer.call(raw_content)
  end

  private

  def should_update_latest_activity?
    content.pubdate > 1.week.ago && content.channel_type != 'Event'
  end
end
