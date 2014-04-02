class IssuesController < ApplicationController
  def index
  end

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
  end

  def update
  end

  def new
  end

  def create
  end

  def destroy
  end
end
