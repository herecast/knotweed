class Contents::FacebookScrapingsController < ApplicationController

  def create
    @content = Content.find(params[:content_id])
    BackgroundJob.perform_later('FacebookService', 'rescrape_url', @content)
    flash[:notice] = "Content with ID: #{@content.id} has been rescraped"
    redirect_to contents_path
  end
end