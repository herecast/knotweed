# frozen_string_literal: true

# == Schema Information
#
# Table name: user_bookmarks
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  content_id        :integer
#  event_instance_id :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  read              :boolean          default(FALSE)
#  deleted_at        :datetime
#
# Indexes
#
#  index_user_bookmarks_on_content_id  (content_id)
#  index_user_bookmarks_on_deleted_at  (deleted_at)
#  index_user_bookmarks_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (content_id => contents.id)
#  fk_rails_...  (user_id => users.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :like do
    user
    content
  end
end
