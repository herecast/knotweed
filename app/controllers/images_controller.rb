class ImagesController < ApplicationController

  def show
    @image = Image.find(params[:id])
  end

  def index
    @images = Image.all
  end

  def create
    @image = Image.create(params[:image])
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
    if @image.update_attributes(params[:image])
      respond_to do |format|
        format.js
      end
    end
  end

end
