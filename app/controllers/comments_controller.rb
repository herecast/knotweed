# frozen_string_literal: true

class CommentsController < ApplicationController
  def index
    if params[:reset]
      session[:comment_search] = nil
    elsif params[:q].present?
      params[:q] ||= {}
      session[:comment_search] = params[:q]
    end

    @search = Comment.ransack(session[:comment_search])

    @comments = if session[:comment_search].present?
                  @search.result(distinct: true)
                         .order('created_at DESC')
                         .page(params[:page])
                         .per(25).includes(:created_by)
                else
                  []
                end
  end

  def update
    @comment = Comment.find(params[:id])
    @comment.update_attribute(:deleted_at, nil)
    @comment.increase_comment_stats
    flash[:info] = 'Comment Unhidden'
    redirect_to correct_path
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.update_attribute(:deleted_at, Time.now)
    @comment.decrease_comment_stats
    notify_comment_owner
    notify_parent_content_owner
    flash[:info] = 'Comment Hidden'
    redirect_to correct_path
  end

  private

  def correct_path
    !!params[:from_content_form] ? contents_path : comments_path
  end

  def notify_comment_owner
    ContentRemovalAlertMailer.content_removal_alert(@comment).deliver_later
  end

  def notify_parent_content_owner
    CommentAlertMailer.alert_parent_content_owner(
      @comment, @comment.content, true
    ).deliver_later
  end
end
