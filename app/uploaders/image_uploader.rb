# frozen_string_literal: true

class ImageUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  # include CarrierWave::MimetypeFu

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    # "uploads/#{model.class.to_s.underscore}/#{model.id}"
    # new one
    if Rails.env.test?
      "#{Rails.root}/spec/support/uploads"
    elsif model.methods.include?(:imageable) && model.imageable.present?
      "#{model.imageable_type.underscore}/#{model.imageable.id}"
    elsif model.class == Caster
        "user/#{model.id}"
    elsif model.class != Image # i.e. if it's an organization
      "#{model.class.to_s.underscore}/#{model.id}"
    else
      'uploads'
    end
  end

  process :store_dimensions_and_type

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :scale => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w[jpg jpeg png]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "#{secure_token}-#{original_filename}" if original_filename.present?
  end

  def timestamp
    var = :"@#{mounted_as}_timestamp"
    model.instance_variable_get(var) || model.instance_variable_set(var, Time.current.to_i)
  end

  def secure_token(length = 16)
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.hex(length / 2))
  end

  def full_cache_path
    "#{::Rails.root}/public/#{cache_dir}/#{cache_name}"
  end

  private

  def store_dimensions_and_type
    if file && model && model.class == Image
      model.width, model.height = ::MiniMagick::Image.open(file.file)[:dimensions]
      model.file_extension = file.extension
    end
  end
end
