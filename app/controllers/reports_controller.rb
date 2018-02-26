class ReportsController < ApplicationController
  load_and_authorize_resource

  def index
  end

  def new
  end

  def edit
    @users = User.where("(select count(user_id) from users_roles where user_id=users.id) > 0").includes(:roles)
    @recipient_user_ids = @report.report_recipients.map(&:user_id)
  end

  def create
    if @report.save
      flash[:notice] = "Created report with id #{@report.id}"
      redirect_to reports_path
    else
      render 'new'
    end
  end

  def update
    if @report.update_attributes(report_params)
      flash[:notice] = "Successfully updated report #{@report.id}"
      redirect_to reports_path
    else
      render 'edit'
    end
  end

  private

  def report_params
    params.require(:report).permit(
      :title,
      :report_path,
      :output_file_name,
      :output_formats_review,
      :output_formats_send,
      :email_subject,
      :repository_folder,
      :overwrite_files,
      :notes,
      :alert_recipients,
      :cc_email,
      :bcc_email,
      report_params_attributes: [:param_name, :param_value,
        :_destroy, :id, :report_param_type]
    )
  end
end
