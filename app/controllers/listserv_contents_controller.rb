class ListservContentsController < ApplicationController
  before_action :set_listserv_content, only: [:edit, :update, :destroy]

  def index
    if params[:q].present?
      session[:listserv_contents_search] = params[:q]
    end

    model_scope = ListservContent
    if session[:listserv_contents_search].present? && session[:listserv_contents_search][:deleted_at_not_null].present?
      model_scope = model_scope.with_deleted
    end

    @search = model_scope.ransack(session[:listserv_contents_search])
    scope = @search.result(distinct: true).order('created_at DESC')

    @listserv_contents = scope.page(params[:page] || 1).per(params[:per_page] || 100)
  end

  def show
    @listserv_content = ListservContent.with_deleted.find(params[:id])
  end

  def new
    @listserv_content = ListservContent.new
  end

  def edit
  end

  def create
    @listserv_content = ListservContent.new(listserv_content_params)

    ensure_verify_ip

    respond_to do |format|
      if @listserv_content.save
        format.html { redirect_to @listserv_content, notice: 'Listserv content was successfully created.' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      @listserv_content.attributes = listserv_content_params
      ensure_verify_ip
      if @listserv_content.save
        format.html { redirect_to @listserv_content, notice: 'Listserv content was successfully updated.' }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @listserv_content.update deleted_at: Time.current, deleted_by: current_user.name
    respond_to do |format|
      format.html { redirect_to listserv_contents_url }
      format.js
    end
  end

  def undelete
    @listserv_content = ListservContent.unscoped.find(params[:id])
    @listserv_content.update(
      deleted_at: nil,
      deleted_by: nil
    )

    respond_to do |format|
      format.html { redirect_to @listserv_content }
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_listserv_content
      @listserv_content = ListservContent.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def listserv_content_params
      params.require(:listserv_content).permit(
        :sender_name, :sender_email, :subject, :body, :content_category_id,
        :verified_at, :content_id, :listserv_id, :user_id, :subscription_id
      )
    end

    def ensure_verify_ip
      if @listserv_content.verified_at? && !@listserv_content.verify_ip
        @listserv_content.verify_ip = request.remote_ip
      end
    end
end
