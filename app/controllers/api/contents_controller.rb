class Api::ContentsController < Api::ApiController

  # for now, this doesn't need to handle images
  def create_and_publish
    # find source_id from source name
    source = params[:content].delete :source
    pub = Publication.find_by_name(source)

    @content = Content.new(params[:content])
    @content.source = pub
    @content.pubdate = @content.timestamp = Time.zone.now
    if @content.save
      if @content.publish(Content::POST_TO_ONTOTEXT)
        render text: "Content created and published"
      else
        render text: "Content was created, but not published", status: 500
      end
    else
      render text: "Content could not be created", status: 500
    end
  end

end
