class Admin::ParsersController < Admin::AdminController
  load_and_authorize_resource
  respond_to :html

  # method for returning parameter fields via ajax
  def parameters
    @parameters = Parameter.where("parser_id = ?", params[:id])
    render partial: "admin/parsers/partials/parameters_fields"
  end

  def new
  end

  def create
    @parser = Parser.new(params[:parser])
    @parser.organization = current_user.organization unless @parser.organization.present?
    if @parser.save
      flash[:notice] = "Parser saved."
      redirect_to admin_parsers_path
    else
      render 'new'
    end
  end

  def index
  end

  def edit
  end
  
  def update
    @parser = Parser.find(params[:id])
    if @parser.update_attributes(params[:parser])
      flash[:notice] = "Successfully updated parser."
    end
    respond_with(@parser, location: admin_parsers_url)
  end
  
end
