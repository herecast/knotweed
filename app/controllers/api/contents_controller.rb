class Api::ContentsController < Api::ApiController

  # for now, this doesn't need to handle images
  def create_and_publish
    # find source_id from source name
    source = params[:content].delete :source
    pub = Publication.find_by_name(source)
    repo = Repository.find_by_dsp_endpoint(params[:repository])

    @content = Content.new(params[:content])
    @content.source = pub
    @content.pubdate = @content.timestamp = Time.zone.now
    if @content.save
      if @content.publish(Content::POST_TO_ONTOTEXT, repo)
        render text: "#{@content.id}"
      else
        render text: "Content was created, but not published", status: 500
      end
    else
      render text: "Content could not be created", status: 500
    end
  end

  # returns hash of IDs representing a full thread of conversation
  def get_tree
    if Content.exists? params[:id]
      @content = Content.find params[:id] 
      @repo = Repository.find_by_dsp_endpoint(params[:repository])
      thread = @content.get_full_ordered_thread
      # requested to remove this functionality because our published flag
      # is not always accurate right now. NG's opinion is that we should work
      # on making the published flag accurate rather than removing this filter
      # but to each their own I suppose.
      #thread.select! { |pair| @repo.contents.include? Content.find(pair[0]) }
      render json: thread
    else
      render json: {}
    end
  end

end
