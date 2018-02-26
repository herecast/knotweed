class ReportRecipientsController < ApplicationController
  load_and_authorize_resource

  def new
    @report_recipient.report = Report.find params[:report_id]
    @report_recipient.user = User.find params[:user_id]
    render partial: 'report_recipients/partials/form', layout: false
  end

  def create
    if @report_recipient.save
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js { render json: @report_recipient.errors }
      end
    end
  end

  def edit
    render partial: 'report_recipients/partials/form', layout: false
  end

  def update
    if @report_recipient.update_attributes(report_recipient_params)
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js { render json: @report_recipient.errors } 
      end
    end
  end

  def destroy
    @report_recipient.destroy
    respond_to do |format|
      format.js
    end
  end

  private

  def report_recipient_params
    params.require(:report_recipient).permit(
      :report_id,
      :user_id,
      :alternative_emails
    )
  end
end
