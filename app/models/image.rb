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
#  primary        :boolean          default(FALSE)
#  width          :integer
#  height         :integer
#  file_extension :string
#  position       :integer          default(0)
#

class Image < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :imageable, polymorphic: true, inverse_of: :images,
    touch: true

  mount_uploader :image, ImageUploader
  skip_callback :commit, :after, :remove_previously_stored_image

  # validates_presence_of :image
  validates :image, :image_minimum_size => true

  after_save :ensure_only_one_primary

  scope :in_rendering_order, -> { order("#{self.table_name}.position ASC, #{self.table_name}.created_at ASC") }

  def url
    image.try(:url)
  end

  # alias for rails_admin to find label method
  def name
    image_identifier
  end

  # if the image is primary, be sure to set other images belonging to the same
  # imageable as not primary
  def ensure_only_one_primary
    if imageable.present?
      other_images = imageable.images.where('id != ?', id)
      if primary
        other_images.update_all primary: false
      end
    end
  end

  def remove_image=(val)
    image_will_change! if val
    super
  end

end
