class Image < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :imageable, polymorphic: true, inverse_of: :images
  
  attr_accessible :caption, :credit, :image, :image_cache, :remove_image, 
                  :imageable_id, :imageable_type, :remote_image_url,
                  :source_url
  
  mount_uploader :image, ImageUploader
  
#  validates_presence_of :image
  
  # alias for rails_admin to find label method
  def name
    image_identifier
  end
  
end
