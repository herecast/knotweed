class MarketPostsController < ApplicationController

  def index
    # if posted, save to session
    if params[:reset]
      session[:market_posts_search] = nil
    elsif params[:q].present?
      params[:q][:id_in] = params[:q][:id_in].split(',').map { |s| s.strip } if params[:q][:id_in].present?
      session[:market_posts_search] = params[:q]
    end

    session[:market_posts_search][:channelized_false] = true if session[:market_posts_search].present?

    @search = MarketPost.ransack(session[:market_posts_search])

    if session[:market_posts_search].present?
#      @market_posts = @search.result(distinct: true).joins(market_post: :content).order('pubdate DESC').page(params[:page]).per(100)
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

    @market_post.content = Content.new(channel_type: 'MarketPost')
    @market_post.content.images.build
    @market_post.content.content_category_id = ContentCategory.find_or_create_by_name('market').id

    # hard coding some other things
    @market_post.content.category_reviewed = true
    # again with the under protest...
    @market_post.content.publication_id = Publication.find_or_create_by_name('Subtext Market Posts').id

    # for users that can only access certain specific attribute contents
    current_ability.attributes_for(:new, Content).each do |key,value|
      @market_post.send("#{key}=", value)
    end
    authorize! :new, @market_post
  end

  def create
    @market_post = MarketPost.new(params[:market_post])
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

    if @market_post.update_attributes(params[:market_post])
      # re-publish updated content
      publish_success = false
      if current_user.default_repository.present?
        publish_success = @market_post.content.publish(Content::DEFAULT_PUBLISH_METHOD, current_user.default_repository)
      end
      flash[:notice] = "Successfully updated market post #{@market_post.id}"
      if publish_success
        flash[:notice] = flash[:notice] + ' and re-published'
      else
        flash[:warning] = 'Publish failed'
      end
      redirect_to form_submit_redirect_path(@market_post.id)
    else
      render 'edit'
    end
  end

  def destroy
  end

  private

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
end
