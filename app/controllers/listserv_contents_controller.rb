class ListservContentsController < ApplicationController
  before_action :set_listserv_content, only: [:show, :edit, :update, :destroy]

  def index
    if params[:q].present?
      session[:listserv_contents_search] = params[:q]
    end

    @search = ListservContent.ransack(session[:listserv_contents_search])
    scope = @search.result(distinct: true).order('created_at DESC')

    @listserv_contents = scope.page(params[:page] || 1).per(params[:per_page] || 100)
  end

  def show
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
    @listserv_content.destroy
    respond_to do |format|
      format.html { redirect_to listserv_contents_url }
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
