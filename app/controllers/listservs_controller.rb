class ListservsController < ApplicationController
  before_action :set_listserv, only: [:show, :edit, :update, :destroy]

  def index
    # if posted, save to session
    if params[:reset]
      session[:listservs_search] = nil
    elsif params[:q].present?
      session[:listservs_search] = params[:q]
    end
    unless session[:listservs_search].present?
      session[:listservs_search] = { :active_true => true }
    end
    @search = Listserv.ransack(session[:listservs_search])
    @listservs = @search.result(distinct: true)
  end

  def show
  end

  def new
    # default list type should be custom digest
    @listserv = Listserv.new(list_type: 'custom_digest')
  end

  def edit
    @digest_days = Listserv.digest_days
  end

  def create
    @listserv = Listserv.new(listserv_params)

    if @listserv.save
      redirect_to listservs_url, notice: 'Listserv was successfully created.'
    else
      render action: 'new'
    end
  end

  def update
    if @listserv.update(listserv_params)
      redirect_to listservs_url, notice: 'Listserv was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @listserv.destroy
    redirect_to listservs_url
  end

  private
    def set_listserv
      @listserv = Listserv.find(params[:id])
    end

    def listserv_params
      params.require(:listserv).permit(
        :active,
        :import_name,
        :name,
        :reverse_publish_email,
        :subscribe_email,
        :unsubscribe_email,
        :post_email,
        :digest_send_time,
        :mc_list_id,
        :mc_group_name,
        :digest_header,
        :digest_footer,
        :send_digest,
        :digest_reply_to,
        :timezone,
        :digest_description,
        :digest_send_day,
        :digest_query,
        :template,
        :sponsored_by,
        :display_subscribe,
        :digest_preheader,
        :digest_subject,
        :list_type,
        :sender_name,
        :admin_email,
        :promotions_list,
        :forwarding_email,
        :forward_for_processing,
        :post_threshold,
        promotion_ids: []
      )
    end
end
