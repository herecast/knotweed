# == Schema Information
#
# Table name: category_corrections
#
#  id           :integer          not null, primary key
#  content_id   :integer
#  old_category :string(255)
#  new_category :string(255)
#  user_email   :string(255)
#  title        :string(255)
#  content_body :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  idx_16473_index_category_corrections_on_content_id  (content_id)
#

class CategoryCorrection < ActiveRecord::Base

  belongs_to :content

  validates_presence_of :content

  after_create :update_content, :remove_previous_category_corrections

  def update_content
    update_attributes( content_body: content.content, title: content.title )
    category = ContentCategory.find_or_create_by(name: new_category)
    content.update_attribute :content_category, category
    # mark reviewed
    content.update_attribute :category_reviewed, true
  end
  
  # it was requested that we remove all previous category corrections when a new one is added...
  def remove_previous_category_corrections
    CategoryCorrection.where(content_id: content_id).where("id != ?", id).destroy_all
  end

end
