class ContentsController < ApplicationController

  def index
    # this is a stopgap solution. I need to get a better understanding
    # of how this works, but for now it seems to be cleaning up our crash issue.
    @contents = Content.all
  end

  def show
    @content = Content.find(params[:id])
  end
end
