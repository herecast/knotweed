class AnnotationReport < ActiveRecord::Base

  belongs_to :content
  has_many :annotations

  attr_accessible :content_id, :name, :description

  default_scope order('created_at DESC')
end
