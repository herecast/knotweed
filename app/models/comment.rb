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
  attr_accessible :content_attributes
  validates_associated :content

  has_one :source, through: :content, class_name: "Publication", foreign_key: "publication_id"
  has_one :content_category, through: :content
  has_many :images, through: :content
  has_many :repositories, through: :content
  has_one :import_location, through: :content

  attr_accessible :tier # this is not stored on the database, but is used to generate a tiered tree
  # for the API

  after_save do |comment|
    comment.content.save
  end

  after_create do |comment|
    unless self.content.parent.blank?
      self.content.parent.increment(:comment_count)
      count = Content.where('parent_id=? and created_by=? and id!=?', self.content.parent, self.content.created_by, self.content.id).count
      if count == 0
        self.content.parent.increment(:commenter_count) 
      end
      self.content.parent.save
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
