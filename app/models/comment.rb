# == Schema Information
#
# Table name: comments
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Comment < ActiveRecord::Base
  has_one :content, as: :channel
  accepts_nested_attributes_for :content
  validates_associated :content

  has_one :source, through: :content, class_name: "Organization", foreign_key: "organization_id"
  has_one :content_category, through: :content
  has_many :images, through: :content
  has_many :repositories, through: :content
  has_one :import_location, through: :content

  after_save do |comment|
    comment.content.save
  end

  after_create do |comment|
    unless content.parent.blank?
      content.parent.increment_integer_attr!(:comment_count)
      unless Content.where('parent_id=? and created_by=? and id!= ?', content.parent, content.created_by, content.id).exists?
        content.parent.increment_integer_attr!(:commenter_count) 
      end
      content.parent.save
    end
  end

  def method_missing(method, *args, &block)
    if respond_to_without_attributes?(method)
      send(method, *args, &block)
    else
      if content.respond_to?(method)
        content.send(method, *args, &block)
      else
        super
      end
    end
  end

end
