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

  validates_presence_of :content

  # this has to be after_commit because otherwise, if
  # the DSP call times out, the original save transaction
  # times out and throws a MySQL lock error
  after_commit :publish_corrections_to_dsp
  
  after_create :update_content, :remove_previous_category_corrections

  def update_content
    update_attributes( content_body: content.content, title: content.title )
    category = ContentCategory.find_or_create_by(name: new_category)
    content.update_attribute :content_category, category
    # mark reviewed
    content.update_attribute :category_reviewed, true
  end

  def publish_corrections_to_dsp
    # update for all repos
    content.repositories.each do |r|
      content.publish(Content::DEFAULT_PUBLISH_METHOD, r)
    end
  end
  
  # it was requested that we remove all previous category corrections when a new one is added...
  def remove_previous_category_corrections
    CategoryCorrection.where(content_id: content_id).where("id != ?", id).destroy_all
  end

end
