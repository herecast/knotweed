class Admin::PublishJobsController < Admin::AdminController

  def new
  end

  def contents_count

    @count = contents_query.count
    respond_to do |format|
      format.js
    end

  end

  private

  def contents_query
    query = {
      quarantine: false, # can't publish quarantined docs
      published: false # default to not yet published
    }
    if params[:content][:source_id].present?
      query[:source_id] = params[:content][:source_id].map { |s| s.to_i } 
    end
    if params[:content][:location_id].present? and params[:content][:location_id].count > 1
      query[:location_id] = params[:content][:location_id].map { |s| s.to_i } 
    end
    if params[:published] == "true"
      query[:published] = true
    elsif params[:published] == "both"
      query.delete(:published)
    end
    contents = Content.where(query)
    contents = contents.where("pubdate >= ?", Date.parse(params[:from])) if params[:from].present?
    contents = contents.where("pubdate <= ?", Date.parse(params[:to])) if params[:to].present?
    return contents
  end
    
end
