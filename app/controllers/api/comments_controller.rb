class Api::CommentsController < Api::ApiController

  def create_and_publish
    category = params[:content][:category]
    pub_name = params[:content].delete :publication
    pub = Publication.find_by_name(pub_name)

    # destinations for reverse publishing
    listservs = params[:content].delete :listservs

    cat_name = params[:content].delete :category
    cat = ContentCategory.find_or_create_by_name(cat_name) unless cat_name.nil?

    # create content record to associate with the new comment
    content_record = {}
    content_record['title'] = params[:content].delete(:title)
    content_record['raw_content'] = params[:content].delete(:content)
    content_record['authors'] = params[:content].delete(:authors)
    content_record['authoremail'] = params[:content].delete(:authoremail)
    # content_record['images'] = [market_post_image] if market_post_image.present?
    content_record['content_category_id'] = cat.id
    content_record['publication_id'] = pub.id
    content_record['pubdate'] = content_record['timestamp'] = Time.zone.now

    # create the new comment and the associated content record
    @comment = Comment.new
    @comment.content_attributes = content_record

    if @comment.save
      # do reverse publishing if applicable
      if listservs.present?
        listservs.each do |d|
          next if d.empty?
          list = Listserv.find(d.to_i)
          PromotionListserv.create_from_content(@comment.content, list) if list.present? and list.active
        end
      end
      # regular publishing to DSP
      repo = Repository.find_by_dsp_endpoint(params[:repository])
      if repo.present? and @comment.publish(Content::DEFAULT_PUBLISH_METHOD, repo)
        render text: "#{@comment.id}"
      else
        render text: "Comment #{@comment.id} was created, but not published", status: 500
      end
    else # if saving fails
      render text: "Comment could not be created", status: 500
    end
  end

end
