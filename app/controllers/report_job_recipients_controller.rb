class ReportJobRecipientsController < ApplicationController
  load_and_authorize_resource

  def destroy
    @report_job_recipient.destroy
    respond_to do |format|
      format.js
    end
  end

  def edit
    render partial: 'report_job_recipients/partials/form', layout: false
  end

  def update
    if @report_job_recipient.update_attributes(report_job_recipient_params)
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js { render json: @report_job_recipient.errors } 
      end
    end
  end

  # this is just used for error display
  def show
    render 'report_job_recipients/show', layout: false
  end

  private

  def report_job_recipient_params
    params.require(:report_job_recipient).permit(
      report_job_params_attributes: [:id, :param_name, :param_value, :_destroy]
    )
  end
end
