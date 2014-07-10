class CategoryCorrection < ActiveRecord::Base

  belongs_to :content

  attr_accessible :content_body, :content, :new_category, :old_category, :title, :user_email

  validates_presence_of :content

  after_create :update_content

  def update_content
    update_attributes( content_body: content.content, title: content.title )
    content.update_attribute :categories, new_category
    # update for all repos
    content.repositories.each do |r|
      content.publish(Content::POST_TO_ONTOTEXT, r)
    end
  end

end
