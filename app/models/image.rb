class Image < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true, inverse_of: :images
  
  attr_accessible :caption, :credit, :image, :image_cache, :remove_image, 
                  :imageable_id, :imageable_type, :remote_image_url,
                  :source_url
  
  mount_uploader :image, ImageUploader
  
#  validates_presence_of :image
  
  rails_admin do
    nested do
      include_all_fields
      field :imageable do
        visible false
      end
    end
    
    edit do
      field :imageable do
        label "Type | Content"
      end
      field :caption
      field :credit
      field :image
    end
    
    list do
      field :id
      field :imageable_type do
        label "Content Type"
      end
      field :imageable do
        label "Attached Content"
      end
      field :image
      field :caption
    end
    
  end
  
  # alias for rails_admin to find label method
  def name
    image.try(:identifier)
  end
  
end
