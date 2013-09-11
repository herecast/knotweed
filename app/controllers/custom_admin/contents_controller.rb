class CustomAdmin::ContentsController < ContentsController
  java_import java.util.Date
  

  def index
    query = DocumentQuery.new() 
    query.setMaxResultLength(100)
    query.setSortFeature("TIMESTAMP", true)

    querystring = ""
    if params[:source].present?
      querystring << " and " unless querystring.empty?
      querystring << "SOURCE:#{params[:source].strip}"
    end
    if params[:title].present?
      querystring << " and " unless querystring.empty?
      querystring << "TITLE:#{params[:title].strip}"
    end
    if params[:authors].present?
      querystring << " and " unless querystring.empty?
      querystring << "AUTHORS:#{params[:authors].strip}"
    end
    if querystring.present?
      # query.setKeywordRestriction(querystring)
    end

    # date range filtering
    if params[:from].present?
      # gsub - for / bc java date doesn't like the dash format
      #query.setTimeIntervalStartDate(java.util.Date.new(params[:from].gsub("-", "/")))
    end
    if params[:to].present?
      #query.setTimeIntervalEndDate(java.util.Date.new(params[:to].gsub("-", "/")))
    end

    listDocIDs = @@apiDR.getDocumentIds(query)
    @contents = []
    listDocIDs.each do |id|
      @contents << @@apiDR.loadDocument(id.getDocumentId())
    end
  end

end
