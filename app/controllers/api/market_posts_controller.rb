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

    @contents = @contents.includes(:publication).includes(:content_category).includes(:images)

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

    params[:page] ||= 1
    params[:per_page] ||= 30
    @contents = @contents.page(params[:page].to_i).per(params[:per_page].to_i)
    @page = params[:page]
    @pages = @contents.total_pages unless @contents.empty?

    render "api/contents/index"
  end

  def show
    @market_post = MarketPost.find(params[:id])
    if params[:repository].present?
      @market_post = nil unless @market_post.content.published
    end
  end

  def create
  end

  def update
  end
end
