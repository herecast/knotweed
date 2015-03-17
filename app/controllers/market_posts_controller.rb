class MarketPostsController < ApplicationController

  def index
    # if posted, save to session
    if params[:reset]
      session[:market_posts_search] = nil
    elsif params[:q].present?
      if params[:q][:id_in].present?
        params[:q][:id_in] = params[:q][:id_in].split(',').map{ |s| s.strip }
      end
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
    redirect_to edit_content_path(params[:id])
  end

  def new
    @market_post = MarketPost.new
    # if this is curating an existing piece of content, we get passed "unchannelized_content_id"
    # and use that to construct our new content
    if params[:unchannelized_content_id].present?
      unchannelized_content = Content.find(params[:unchannelized_content_id])
      @market_post.content = unchannelized_content.dup
      # we pass in a placeholder for the image url so that we can display it
      # (if the original content had an image),
      # then in create we duplicate the original image and assign it to the new content.
      @placeholder_image = unchannelized_content.images.first
      @market_post.content.title = remove_list_from_title(unchannelized_content.title)
    else
      @market_post.content = Content.new(channel_type: 'MarketPost')
    end

    @market_post.content.images.build unless @market_post.content.images.present?

    # set default fields for event channelized content here

    # for the record, I hate this. That we're hard coding "event" which is represented by a database
    # field *throughout* the codebase. It's done under protest.
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
    begin
      if @market_post.save!
        publish_success = false
        if current_user.default_repository.present?
          publish_success = @market_post.content.publish(Content::POST_TO_NEW_ONTOTEXT, current_user.default_repository)
        end

        flash[:notice] = "Created market post with id #{@market_post.id}"
        if publish_success == true
          flash[:notice] = flash[:notice] + ' and published successfully'
        elsif publish_success == false
          flash[:warning] = 'Publish failed'
        end
        redirect_to form_submit_redirect_path(@market_post.id)
      else
        render "new"
      end
    rescue
      flash[:notice] = 'Creating the new market post failed'
      render "new"
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
        publish_success = @market_post.content.publish(Content::POST_TO_NEW_ONTOTEXT, current_user.default_repository)
      end
      flash[:notice] = "Successfully updated market post #{@market_post.id}"
      if publish_success == true
        flash[:notice] = flash[:notice] + ' and re-published'
      elsif publish_success == false
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
