class RewritesController < ApplicationController
  load_and_authorize_resource

  def index
  end
  def edit
  end
  def new
  end

  def create
    @rewrite = Rewrite.new(params[:rewrite])
    if @rewrite.save
      flash[:notice] = "Rewrite saved."
      redirect_to rewrites_path
    else
      render 'new'
    end
  end

  def update
    @rewrite = Rewrite.find(params[:id])
    if @rewrite.update_attributes(params[:rewrite])
      flash[:notice] = 'Successfully updated rewrite.'
    end
    respond_with(@rewrite, location: rewrites_url)
  end

  def destroy
    @rewrite = Rewrite.destroy(params[:id])
    respond_to do |format|
      format.js
    end
  end
  
end
