class Admin::ContentsController < Admin::AdminController

  def index
    # if posted, save to session
    if params[:q].present?
      session[:contents_search] = params[:q]
    end
    
    @search = Content.search(session[:contents_search])
    if session[:contents_search].present?
      @contents = @search.result(distinct: true).order("pubdate DESC").page(params[:page]).per(100)
    else
      @contents = []
    end
  end

  def new
    @content = Content.new
  end

  def create
    image_list = params[:content].delete(:image_list)
    image_ids = image_list.try(:split, ",")
    @content = Content.new(params[:content])
    connection = nil
    if @content.save
      image_ids.each do |image_id|
        image = Image.find(image_id)
        old_path = "uploads/#{image.image.file.filename}"
        @content.images << image
        image = Image.find(image_id)
        new_path = image.image.path.to_s
        if old_path != new_path
          if connection.nil?
            connection = Fog::Storage.new({
              provider: "AWS",
              aws_access_key_id: Figaro.env.aws_access_key_id,
              aws_secret_access_key: Figaro.env.aws_secret_access_key
            })
          end
          # unfortunately we have to copy directly on AWS here
          connection.copy_object(Figaro.env.aws_bucket_name, old_path, Figaro.env.aws_bucket_name, new_path)
          connection.delete_object(Figaro.env.aws_bucket_name, old_path)
        end
      end
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
