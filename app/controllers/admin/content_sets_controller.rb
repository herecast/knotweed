class Admin::ContentSetsController < Admin::AdminController
  load_and_authorize_resource

  def index
    @search = ContentSet.search(params[:q])
    if params[:q].present?
      @content_sets = @search.result(distinct: true)
    else
      @content_sets = ContentSet.all
    end
  end

  def new
  end

  def show
  end

  def edit
  end

  def update
    if @content_set.update_attributes(params[:content_set])
      flash[:notice] = "Successfully updated content set #{@content_set.id}"
      redirect_to admin_content_sets_path
    else
      render "edit"
    end
  end

  def create
    if @content_set.save
      flash[:notice] = "Created content set with id #{@content_set.id}"
      redirect_to admin_content_sets_path
    else
      render "new"
    end
  end

  def destroy
    @content_set.destroy
  end


end
