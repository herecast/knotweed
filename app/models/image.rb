# == Schema Information
#
# Table name: images
#
#  id             :integer          not null, primary key
#  caption        :string(255)
#  credit         :string(255)
#  image          :string(255)
#  imageable_type :string(255)
#  imageable_id   :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  source_url     :string(400)
#

class Image < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :imageable, polymorphic: true, inverse_of: :images
  
  attr_accessible :caption, :credit, :image, :image_cache, :remove_image, 
                  :imageable_id, :imageable_type, :remote_image_url,
                  :source_url, :imageable, :primary
  
  mount_uploader :image, ImageUploader
  
  # validates_presence_of :image
  
  after_save :ensure_only_one_primary
  
  # alias for rails_admin to find label method
  def name
    image_identifier
  end

  # if the image is primary, be sure to set other images belonging to the same
  # imageable as not primary
  def ensure_only_one_primary
    if imageable.present?
      other_images = imageable.images.where('id != ?', id)
      if !other_images.present? # then this is the only image
        update_attribute :primary, true unless primary
      elsif primary
        other_images.update_all primary: false
      end
    end
  end

  # returns the original filename by using a regexp to remove the SecureRandom.hex
  # we add to filenames (if present -- older filenames don't have that)
  def original_filename
    File.basename(image.path).match(/([0-9a-f]*-)?(.+)/)[2] if image.present?
  end

end
