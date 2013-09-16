class CustomAdmin::ContentsController < ContentsController
  java_import java.util.Date
  

  def index
    @contents = []
    listDocIDs = nil
    System.gc()

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
      query.setKeywordRestriction(querystring)
    end

    # date range filtering
    if params[:from].present?
      # gsub - for / bc java date doesn't like the dash format
      query.setTimeIntervalStartDate(java.util.Date.new(params[:from].gsub("-", "/")))
    end
    if params[:to].present?
      query.setTimeIntervalEndDate(java.util.Date.new(params[:to].gsub("-", "/")))
    end

    listDocIDs = @@apiDR.getDocumentIds(query)
    listDocIDs.each do |id|
      @contents << @@apiDR.loadDocument(id.getDocumentId())
    end
  end

  def edit
    document = @@apiDR.loadDocument(params[:id].to_i)
    @content = document.content
    @features = document.features
    @id = params[:id]
    @doc = document
  end

  def update
    # todo: abstract documents into their own model
    # and create an update method that handles all of this.
    document = @@apiDR.loadDocument(params[:id].to_i)
    features = document.features

    # have to use hardcoded list of features here instead
    # of features.keys because features.keys doesn't return
    # empty features
    ["TITLE", "SUBTITLE", "AUTHORS", "EDITION", "CATEGORIES",
     "LOCATION", "TOPICS", "COPYRIGHT", "PUBDATE"].each do |key|
      if params.has_key? key.downcase
        # special case for PUBDATE, need to prepare input
        if key == "PUBDATE"
          features[key] = java.util.Date.new(params["#{key.downcase}"].gsub("-", "/"))
        end
        features[key] = params["#{key.downcase}"]
      end
    end
    
    document.set_content params["content"] if params["content"].present?
    document.set_features features
    @@apiDR.syncDocument(document)
    document, features = nil
    flash[:notice] = "Content updated"
    redirect_to custom_admin_contents_path
  end

end
