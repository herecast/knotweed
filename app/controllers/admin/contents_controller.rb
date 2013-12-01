class Admin::ContentsController < Admin::AdminController

  def index
    @search = Content.search(params[:q])
    if params[:q].present?
      @contents = @search.result(distinct: true).order("pubdate DESC").page params[:page]
    else
      @contents = []
    end
  end

  def edit
  end

  def update
  end

  def show
    @content = Content.find(params[:id])
  end

  def publish
    @content = Content.find(params[:id])
    @content.publish
    flash[:notice] = "Content published"
    redirect_to [:admin, @content]
  end

end
