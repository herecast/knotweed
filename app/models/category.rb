# == Schema Information
#
# Table name: categories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  channel_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  idx_16467_index_categories_on_name  (name)
#

class Category < ActiveRecord::Base
  belongs_to :channel
end
