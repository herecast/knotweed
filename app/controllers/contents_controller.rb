class ContentsController < ApplicationController

  before_filter :process_business_loc_params, only: [:create, :update]
  before_filter :process_date_params, only: [:create, :update]
  
  PUBLISH_METHODS_TO_DOWNLOAD = ["export_pre_pipeline_xml", "export_post_pipeline_xml"]

  def index
    # if posted, save to session
    if params[:reset]
      session[:contents_search] = nil
    elsif params[:q].present?
      if params[:q][:id_in].present?
        params[:q][:id_in] = params[:q][:id_in].split(',').map{ |s| s.strip }
      end
      session[:contents_search] = params[:q]
    end
    
    @search = Content.ransack(session[:contents_search])
    if session[:contents_search].present?
      @contents = @search.result(distinct: true).order("pubdate DESC").page(params[:page]).per(100)
    else
      @contents = []
    end
  end

  def new
    @content = Content.new
    @content.build_business_location
    @business_location_options = [["None available.", nil]]
  end

  def create
    # hack to remove duplicate content entry
    params[:content].delete :raw_content1 if params[:content].present?
    image_list = params[:content].delete(:image_list)
    image_ids = image_list.try(:split, ",")
    @content = Content.new(params[:content])
    connection = nil
    @business_location_id = nil
    if @content.save
      if image_ids.present?
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
      end
      flash[:notice] = "Created content with id #{@content.id}"
      redirect_to form_submit_redirect_path(@content.id)
    else
      render "new"
    end
  end

  def edit
    @content = Content.find(params[:id])
    # ensure the form fields aren't filled with a location from the dropdown
    # really pretty hacky...oh well.
    bls = @content.source.try(:business_locations)
    @business_location_options = @content.source.try(:business_location_options) || []
    if bls.present? and bls.include? @content.business_location
      @business_location_id = @content.business_location.id
      # we need to ensure the fields on the right exist
      @content.build_business_location
    elsif @content.business_location.nil?
      @content.build_business_location
    end
  end

  def update
    # hack to remove duplicate content entry
    params[:content].delete :raw_content1 if params[:content].present?
    # ensure serialized values are set to empty if no fields are passed in via form
    params[:content][:links] = nil unless params[:content].has_key? :links
    @content = Content.find(params[:id])
    # if category is changed, create a category_correction object
    # normally I would put this in a callback on the model
    # but given the callbacks already on category_correction and the weirdness
    # of this functionality to begin with, it seems more straightforward
    # to put it here:
    if params[:content][:content_category_id].present? and @content.content_category_id != params[:content][:content_category_id] 
      CategoryCorrection.create(content: @content, old_category: @content.category, 
                                new_category: ContentCategory.find(params[:content][:content_category_id]).name)
      params[:content].delete :content_category_id # already taken care of updating this
    end
    if @content.update_attributes(params[:content])
      flash[:notice] = "Successfully updated content #{@content.id}"
      redirect_to form_submit_redirect_path(@content.id)
    else
      render "edit"
    end
  end

  def show
    flash.keep
    redirect_to edit_content_path(params[:id])
  end

  def destroy
    @content = Content.destroy(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def publish
    @content = Content.find(params[:id])
    opts = {}
    if params[:repository_id].present?
      repo = Repository.find(params[:repository_id])
    else
      repo = nil
    end
    if PUBLISH_METHODS_TO_DOWNLOAD.include? params[:method] 
      opts[:download_result] = true
    end
    if @content.publish(params[:method], repo, nil, opts) == true
      flash[:notice] = "#{params[:method].humanize} successful"
      if opts[:download_result].present? and opts[:download_result].is_a? String
        return send_file opts[:download_result]
      end
    else
      flash[:error] = "#{params[:method].humanize} encountered an error"
    end

    redirect_to @content
  end

  def rdf_to_gate
    @content = Content.find(params[:id])
    repo = Repository.find(params[:repository_id])
    gate_xml = @content.rdf_to_gate(repo)
    if gate_xml == false
      render text: "content #{@content.id} not found on Ontotext server"
    else
      send_data gate_xml, :filename => "#{@content.id}.gate.xml", type: :xml, disposition: 'attachment'
    end
  end

  def parent_select_options
    # check if search query is an integer; if it is, use it as ID query, otherwise title
    if params[:search_query].to_i.to_s == params[:search_query]
      params[:q][:id_eq] = params.delete :search_query
    else
      params[:q][:title_cont] = params.delete :search_query
    end
    conts = Content.ransack(params[:q]).result(distinct: true).order("pubdate DESC")
    if params[:content_id].present?
      @orig_content = Content.find(params[:content_id])
      conts = conts - [@orig_content]
    end
    @contents = conts.map{ |c| [c.title, c.id] }.insert(0,nil)
    respond_to do |format|
      format.js
    end
  end

  private
  def process_business_loc_params
    if params[:content][:business_location_id].present?
      params[:content].delete :business_location_attributes
    else
      params[:content].delete :business_location_id
      if params[:save_to_publication]
        params[:content][:business_location_attributes][:publication_id] = params[:content][:source_id]
      end
    end
  end

  def process_date_params
    if params.has_key? :start_day and params.has_key? :start_time
      Chronic.time_class = Time.zone
      params[:content][:start_date] = Chronic.parse(params[:start_day] + " " + params[:start_time])
      # if end time is specified, but no end day, use start day
      if params[:end_time].present? and !params[:end_day].present?
        params[:end_day] = params[:start_day]
      end
      params[:content][:end_date] = Chronic.parse(params[:end_day] + " " + params[:end_time])
    end
  end

  def form_submit_redirect_path(id=nil)
    if params[:continue_editing]
      edit_content_path(id)
    elsif params[:create_new]
      new_content_path
    else
      contents_path
    end
  end

end
