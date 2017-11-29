class Contents::RemovalsController < ApplicationController

  def create
    @content = Content.find(params[:content_id])
    @content.update_attribute(:removed, true)
    redirect_to edit_content_path(@content)
  end


  def destroy
    @content = Content.find(params[:content_id])
    @content.update_attribute(:removed, false)
    redirect_to edit_content_path(@content)
  end

end