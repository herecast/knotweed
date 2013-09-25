class Admin::ImportJobsController < Admin::AdminController
  load_and_authorize_resource
  
  def index
  end
  
  def new
    @import_job = ImportJob.new
  end
  
  def create
    @import_job = ImportJob.new(params[:import_job])
    @import_job.organization = current_user.organization unless @import_job.organization.present?
    if params[:import_job][:parser_id].present?
      parameters = params[:parameters]
      config = {}
      parameters.each do |key, val|
        config[key.downcase.gsub(" ", "_")] = val
      end
      @import_job.config = config.to_yaml
    end
    if @import_job.save
      flash[:notice] = "Import job saved."
      redirect_to admin_import_jobs_path
    else
      render "new"
    end
  end
  
  def edit
  end
  
  def update
  end
  
  def show
  end
end