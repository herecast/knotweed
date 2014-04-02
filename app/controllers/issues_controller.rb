class IssuesController < ApplicationController
  load_and_authorize_resource

  def select_options
    if params[:publication_id].present?
      issues = Publication.find(params[:publication_id]).issues
    else
      issues = Issue.all
    end
    @issues = issues.map{ |i| [i.issue_edition, i.id]}.insert(0, nil)
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
    @issue.update_attributes!(params[:issue])
    respond_to do |format|
      format.js
    end
  end

  def new
    if params[:publication_id]
      @issue.publication = Publication.find(params[:publication_id])
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
end
