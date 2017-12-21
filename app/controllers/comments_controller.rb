class CommentsController < ApplicationController

  def index
    if params[:reset]
      session[:comment_search] = nil
    elsif params[:q].present?
      params[:q] ||= {}
      params[:q][:channel_type_eq] = 'Comment'
      params[:q][:parent_id_not_null] = 1
      session[:comment_search] = params[:q]
    end

    @search = Content.ransack(session[:comment_search])

    if session[:comment_search].present?
      @comments = @search.result(distinct: true)
        .order("created_at DESC")
        .page(params[:page])
        .per(25)
    else
      @comments = []
    end
  end

  def update
    @comment = Content.find(params[:id])
    if @comment.update_attribute(:deleted_at, nil)
      @comment.channel.increase_comment_stats
      flash[:info] = "Comment Unhidden"
      redirect_to comments_path
    else
      flash.now[:danger] = "Comment was not unhidden"
      render 'index'
    end
  end

  def destroy
    @comment = Content.find(params[:id])
    if @comment.update_attribute(:deleted_at, Time.now)
      @comment.channel.decrease_comment_stats
      flash[:info] = "Comment Hidden"
      redirect_to comments_path
    else
      flash.now[:danger] = "Comment was not hidden"
      render 'index'
    end
  end
end
