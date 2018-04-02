class ReportRecipientsController < ApplicationController
  load_and_authorize_resource except: [:create]

  def new
    @report_recipient.report = Report.find params[:report_id]
    @report_recipient.user = User.find params[:user_id]
    render partial: 'report_recipients/partials/form', layout: false
  end

  def create
    @report_recipient = ReportRecipient.find_or_create_by(user_id: report_recipient_params[:user_id],
                                                        report_id: report_recipient_params[:report_id])
    @report_recipient.alternative_emails = report_recipient_params[:alternative_emails]
    @report_recipient.archived = false
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
    @report_recipient.update archived: true
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
