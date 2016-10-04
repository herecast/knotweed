class IssuesController < ApplicationController
  load_and_authorize_resource

  def select_options
    if params[:organization_id].present?
      issues = Organization.find(params[:organization_id]).issues.order("issue_edition ASC")
    else
      issues = Issue.order("issue_edition ASC")
    end
    @issues = issues.map{ |i| [i.issue_edition, i.id]}.insert(0, nil)
    @selected_id = params[:selected_id]
    respond_to do |format|
      format.js { render "issues/select_options" }
    end
  end

  def edit
    respond_to do |format|
      format.js { render partial: "issues/form" }
    end
  end

  def update
    @issue.update_attributes!(issue_params)
    respond_to do |format|
      format.js
    end
  end

  def show
    respond_to do |format|
      format.js { render json: { issue: @issue } }
    end
  end

  def new
    if params[:organization_id]
      @issue.organization = Organization.find(params[:organization_id])
    end
    render partial: "issues/form", layout:  false
  end

  def create
    @issue.save!
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @issue.destroy
    respond_to do |format|
      format.js
    end
  end

  private

    def issue_params
      params.require(:issue).permit(
        :copyright,
        :issue_edition,
        :publication_date,
        :organization_id,
        :import_location_id
      )
    end

end
