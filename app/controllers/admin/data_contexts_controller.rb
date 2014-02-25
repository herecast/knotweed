class Admin::DataContextsController < Admin::AdminController
  load_and_authorize_resource

  def index
    if params[:reset]
      session[:data_contexts_search] = nil
    elsif params[:q].present?
      session[:data_contexts_search] = params[:q]
      session[:data_contexts_search][:status] = params[:status] if params[:status].present?
    end

    # TODO: I think this (below) would be more elegant as a custom
    # ransack search param but it works for now

    # we have to translate the gaz status query
    # into something usable by ransack
    if session[:data_contexts_search] and session[:data_contexts_search].has_key? :status
      # remove status for generating the ransack object
      desired_status = session[:data_contexts_search].delete :status
      session[:data_contexts_search].delete :archived_eq
      session[:data_contexts_search].delete :loaded_eq
      case desired_status
      when "Loaded"
        session[:data_contexts_search][:loaded_eq] = true
      when "Unloaded"
        session[:data_contexts_search][:loaded_eq] = false
      when "Archived"
        session[:data_contexts_search][:archived_eq] = true
      end
    end
    @search = DataContext.search(session[:data_contexts_search])
    if session[:data_contexts_search].present?
      @data_contexts = @search.result(distinct:true)
    else
      @data_contexts = DataContext.all
    end
    if desired_status.present?
      session[:data_contexts_search][:status] = desired_status
      @status = desired_status
    else 
      @status = nil
    end
  end

  def edit
  end

  def update
    if @data_context.update_attributes(params[:data_context])
      flash[:notice] = "Successfully updated data context #{@data_context.id}"
      redirect_to admin_data_contexts_path
    else
      render "edit"
    end
  end

  def new
  end

  def create
    if @data_context.save
      flash[:notice] = "Created data context with id #{@data_context.id}"
      redirect_to admin_data_contexts_path
    else
      render "new"
    end
  end
end
