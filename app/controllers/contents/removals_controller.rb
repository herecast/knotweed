class Contents::RemovalsController < ApplicationController

  def create
    @content = Content.find(params[:content_id])
    @content.update_attribute(:removed, true)
    rescrape
    redirect_to edit_content_path(@content)
  end


  def destroy
    @content = Content.find(params[:content_id])
    @content.update_attribute(:removed, false)
    rescrape
    redirect_to edit_content_path(@content)
  end

  private

    def rescrape
      BackgroundJob.perform_later('FacebookService', 'rescrape_url', @content)
    end

end