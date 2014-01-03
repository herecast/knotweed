class Admin::ContentsController < Admin::AdminController

  def index
    @search = Content.search(params[:q])
    if params[:q].present?
      @contents = @search.result(distinct: true).order("pubdate DESC").page params[:page]
    else
      @contents = []
    end
  end

  def new
    @content = Content.new
  end

  def create
    @content = Content.new(params[:content])
    if @content.save
      flash[:notice] = "Created content with id #{@content.id}"
      redirect_to admin_contents_path
    else
      render "new"
    end
  end

  def edit
    @content = Content.find(params[:id])
  end

  def update
    @content = Content.find(params[:id])
    if @content.update_attributes(params[:content])
      flash[:notice] = "Successfully updated content #{@content.id}"
      redirect_to admin_contents_path
    else
      render "edit"
    end
  end

  def show
    @content = Content.find(params[:id])
  end

  def publish
    @content = Content.find(params[:id])
    @content.publish(params[:method])
    flash[:notice] = "Content published"
    redirect_to [:admin, @content]
  end

end
