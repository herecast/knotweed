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

class CategoryCorrection < ActiveRecord::Base

  belongs_to :content

  attr_accessible :content_body, :content, :new_category, :old_category, :title, :user_email

  validates_presence_of :content

  after_create :update_content

  def update_content
    update_attributes( content_body: content.content, title: content.title )
    category = ContentCategory.find_or_create_by_name new_category
    content.update_attribute :content_category, category
    # mark reviewed
    content.update_attribute :category_reviewed, true
    # update for all repos
    content.repositories.each do |r|
      content.publish(Content::POST_TO_ONTOTEXT, r)
    end
  end

end
