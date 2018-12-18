# frozen_string_literal: true

class ImagesController < ApplicationController
  def create
    @image = Image.create(image_params)
    # if it's the only image for a given imageable item,
    # set it to 'primary'
    @image.update_attribute :primary, true if @image.try(:imageable).try(:images) == [@image]
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @image = Image.find(params[:id])
    @image.destroy
    respond_to do |format|
      format.js
    end
  end

  def update
    @image = Image.find(params[:id])
    if @image.update_attributes(image_params)
      respond_to do |format|
        format.js
      end
    end
  end

  private

  def image_params
    params.require(:image).permit(
      :caption,
      :credit,
      :image,
      :image_cache,
      :remove_image,
      :imageable_id,
      :imageable_type,
      :remote_image_url,
      :source_url,
      :imageable,
      :primary
    )
  end
end
