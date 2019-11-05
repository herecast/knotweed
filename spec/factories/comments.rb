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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :comment do
    content
    raw_content "This is a comment"
    pubdate { Time.current }
    created_by
  end
end
