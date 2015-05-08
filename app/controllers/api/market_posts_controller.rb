class Api::MarketPostsController < Api::ApiController
  # this is fairly tricky, because at this point, we're combining
  # our original UVMarket logic -- "externally_available" content
  # with content that is market channelized
  #
  # for now, we're just rendering them as though they're all content,
  # and so we can query for externally available AND market channelized content
  def index
    if params[:max_results].present?
      @contents = Content.limit(params[:max_results])
    else
      @contents = Content.limit(1000) #default limit
    end

    #TODO make include images conditional on view
    @contents = @contents.includes(:publication).includes(:content_category).includes(:images)
    #@contents = @contents.includes(:publication).includes(:content_category)

    if params[:sort_order].present? and ['DESC', 'ASC'].include? params[:sort_order] 
      sort_order = params[:sort_order]
    else
      sort_order = "DESC"
    end
    @contents = @contents.order("pubdate #{sort_order}")
    # filter contents by publication based on what publications are allowed
    # for the incoming consumer app
    if @requesting_app.present?
      allowed_pubs = @requesting_app.publications
      @contents = @contents.where(publication_id: allowed_pubs)
    end

    # workaround to avoid the extremely costly contents_repositories inner join
    # using the new "published" boolean on the content model
    # to avoid breaking specs and more accurately replicate the old behavior,
    # we're only introducing this condition when a repository parameter is provided.
    @contents = @contents.published if params[:repository].present?
    
    # we actually can't just have two separate active record relations and then
    # combine them because we need paging, so the alternative is manually
    # doing this left join
    @contents = @contents.joins("LEFT JOIN content_categories_publications ccp ON ccp.content_category_id = contents.content_category_id AND ccp.publication_id = contents.publication_id")
      .where("ccp.content_category_id IS NOT NULL OR contents.channel_type = 'MarketPost'")

    # for the dashboard, if there's an author email, just return their content records.
    @contents = @contents.where(authoremail: params[:authoremail]) if params[:authoremail].present?

    params[:page] ||= 1
    params[:per_page] ||= 30
    @contents = @contents.page(params[:page].to_i).per(params[:per_page].to_i)
    @page = params[:page]
    @pages = @contents.total_pages unless @contents.empty?

    render "api/contents/index"
  end

  def show
    @market_post = MarketPost.find(params[:id])
    # get threaded comments
    @comments = @market_post.content.get_comment_thread

    if params[:repository].present?
      @market_post = nil unless @market_post.content.published
    end
  end

  def create
    pub_name = params[:market_post].delete :publication
    pub = Publication.find_by_name(pub_name)

    cat_name = params[:market_post].delete :category
    cat = ContentCategory.find_or_create_by_name(cat_name) unless cat_name.nil?

    # destinations for reverse publishing
    listserv_ids = params[:market_post].delete :listserv_ids
    
    location_ids = params[:market_post].delete(:location_ids).select{ |id| id.present? }.map{ |id| id.to_i }

    # TODO: there has got to be a better way! but I tried simply piping the image straight through
    # and allowing mass assignment to upload it as you would a normal form submission and no dice, so using
    # JS's solution until we think of something better.
    if params[:market_post][:image].present?
      img = params[:market_post].delete :image
      image_temp_file = Tempfile.new('tmpImage')
      image_temp_file.puts img[:image_content]
      file_to_upload = ActionDispatch::Http::UploadedFile.new(tempfile: image_temp_file,
                                                              filename: img[:image_name], type: img[:image_type])
      market_post_image = Image.new image: file_to_upload
    end

    # create content record to associate with the new market_post record
    content_record = {}
    content_record['title'] = params[:market_post].delete(:title)
    content_record['raw_content'] = params[:market_post].delete(:content)
    content_record['authors'] = params[:market_post].delete(:authors)
    content_record['authoremail'] = params[:market_post].delete(:authoremail)
    content_record['images'] = [market_post_image] if market_post_image.present?
    content_record['content_category_id'] = cat.id
    content_record['publication_id'] = pub.id
    content_record['pubdate'] = content_record['timestamp'] = Time.zone.now
    content_record['location_ids'] = location_ids if location_ids.present?

    # create the new market_post and the associated content record
    @market_post = MarketPost.new(params[:market_post])
    @market_post.content_attributes = content_record

    if @market_post.save

      # reverse publish to specified listservs
      if listserv_ids.present?
        listserv_ids.each do |d|
          next if d.empty?
          list = Listserv.find(d.to_i)
          PromotionListserv.create_from_content(@market_post.content, list) if list.present? and list.active
        end
      end

      repo = Repository.find_by_dsp_endpoint(params[:repository])
      if repo.present? and params[:publish] == "true"
        if @market_post.publish(Content::DEFAULT_PUBLISH_METHOD, repo)
          render text: "#{@market_post.id}"
        else
          render text: "Market Post #{@market_post.id} created but failed to publish", status: 500
        end
      end
    else
      render text: "Market Post could not be created", status: 500
    end  
  end

  def update
    @market_post = MarketPost.find(params[:id])

    # legacy handling of event_description and event_title fields
    params[:market_post][:id] = @market_post.id

    # destinations for reverse publishing
    destinations = params[:market_post].delete :destinations

    # handle images
    if params[:market_post][:image].present?
      hImage = params[:market_post].delete :image
      image_temp_file = Tempfile.new('tmpImage')
      image_temp_file.puts hImage[:image_content]
      file_to_upload = ActionDispatch::Http::UploadedFile.new(tempfile: image_temp_file,
                                                              filename: hImage[:image_name], type: hImage[:image_type])
      market_post_image = Image.new image: file_to_upload
    end

    # need to pass attributes for the content record through content_attributes
    content_attributes = {}
    content_attributes[:id] = @market_post.content.id
    content_attributes[:title] = params[:market_post].delete :title if params[:market_post][:title].present?
    content_attributes[:authors] = params[:market_post].delete :authors if params[:market_post][:authors].present?
    content_attributes[:raw_content] = params[:market_post].delete :content if params[:market_post][:content].present?
    params[:market_post][:content_attributes] = content_attributes

    if @market_post.update_attributes(params[:market_post])
      if market_post_image.present?
        # would just do @market_post.images << @image, but despite the fact
        # that we are set up to have more than one image per content,
        # on the consumer side, we're assuming there's only one image.
        # So to ensure we're displaying the right one, we have to do this.
        @content = @market_post.content
        @content.images = [market_post_image]
        @content.save
      end

      # reverse publish to specified destinations
      if destinations.present?
        destinations.each do |d|
          next if d.empty?
          dest_pub = Publication.find_by_name(d)
          # skip if it doesn't exist or if it can't reverse publish
          next if dest_pub.nil? or !dest_pub.can_reverse_publish
          ReversePublisher.send_market_post_to_listserv(@market_post, dest_pub, @requesting_app).deliver
          logger.debug(dest_pub.name)
        end
      end

      repo = Repository.find_by_dsp_endpoint(params[:repository])
      if repo.present? and params[:publish] == "true"
        if @market_post.publish(Content::DEFAULT_PUBLISH_METHOD, repo)
          render text: "#{@market_post.id}"
        else
          render text: "Market Post #{@market_post.id} updated but failed to publish", status: 500
        end
      else
        render text: "#{@market_post.id}"
      end
    else
      render text: "update of market post #{@market_post.id} failed", status: 500
    end
  end
end
