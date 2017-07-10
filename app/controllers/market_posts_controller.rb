class MarketPostsController < ApplicationController

  def index
    # if posted, save to session
    if params[:reset]
      session[:market_posts_search] = nil
    elsif params[:q].present?
      params[:q][:content_id_in] = format_id_params if params[:q][:content_id_in].present?
      params[:q].each { |key, val| params[:q][key] = '' if val == '0' }
      session[:market_posts_search] = params[:q]
    end

    @search = MarketPost.ransack(session[:market_posts_search])

    if session[:market_posts_search].present?
      @search.sorts = 'created_at desc'
      @market_posts = @search.result(distinct: true).page(params[:page]).per(100)
      @market_posts = @market_posts.accessible_by(current_ability)
    else
      @market_posts = []
    end
  end

  def show
    flash.keep
    redirect_to edit_market_post_path(params[:id])
  end

  def new
    @market_post = MarketPost.new

    @market_post.build_content
    @market_post.content.content_category_id = ContentCategory.find_or_create_by(name: 'market').id
    @market_post.content.images.build

    # hard coding some other things
    @market_post.content.category_reviewed = true
    # again with the under protest...
    @market_post.content.organization_id = Organization.find_or_create_by(name: 'DailyUV').id

    # for users that can only access certain specific attribute contents
    current_ability.attributes_for(:new, MarketPost).each do |key,value|
      @market_post.send("#{key}=", value)
    end
    authorize! :new, @market_post
  end

  def create
    @market_post = MarketPost.new(market_post_params)
    authorize! :create, @market_post
    if @market_post.save
      publish_success = false
      if current_user.default_repository.present?
        publish_success = @market_post.content.publish(Content::DEFAULT_PUBLISH_METHOD, current_user.default_repository)
      end

      flash[:notice] = "Created market post with id #{@market_post.id}"
      if publish_success
        flash[:notice] = flash[:notice] + ' and published successfully'
      else
        flash[:warning] = 'Publish failed'
      end
      redirect_to form_submit_redirect_path(@market_post.id)
    else
      @market_post.content.images.build unless @market_post.content.images.present?
      render 'new'
    end
  end

  def edit
    @market_post = MarketPost.find(params[:id])
    @market_post.content.images.build if @market_post.content.images.empty?
    authorize! :edit, @market_post
  end

  def update
    @market_post = MarketPost.find(params[:id])
    authorize! :update, @market_post

    if @market_post.update_attributes(market_post_params)
      flash[:notice] = "Successfully updated market post #{@market_post.id}"
      handle_republish if current_user.default_repository.present?
      redirect_to form_submit_redirect_path(@market_post.id)
    else
      render 'edit'
    end
  end

  def destroy
  end

  private

    def market_post_params
      params.require(:market_post).permit(
        :content,
        :contact_email,
        :contact_phone,
        :contact_url,
        :cost,
        :latitude,
        :locate_address,
        :locate_include_name,
        :locate_name,
        :longitude,
        :status,
        :preferred_contact_method,
        content_attributes: [ :id, :content_category_id, :category_reviewed, :organization_id, :subtitle, :authors, :copyright, :pubdate, :url, :title, :raw_content, images_attributes: [ :id, :image ] ]
      )
    end

    def format_id_params
      params[:q][:content_id_in].split(',').map { |s| s.strip }
    end

    def form_submit_redirect_path(id=nil)
      if params[:continue_editing]
        edit_market_post_path(id)
      elsif params[:create_new]
        new_market_post_path
      elsif params[:next_record]
        edit_market_post_path(params[:next_record_id], index: params[:index], page: params[:page])
      else
        market_posts_path
      end
    end

    def handle_republish
      publish_success = @market_post.content.publish(Content::DEFAULT_PUBLISH_METHOD, current_user.default_repository)
      if publish_success
        flash[:notice] << ' and re-published'
      else
        flash[:warning] = 'Publish failed'
      end
    end

end
