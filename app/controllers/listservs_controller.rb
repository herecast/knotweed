class ListservsController < ApplicationController
  before_action :set_listserv, only: [:show, :edit, :update, :destroy]

  def index
    @listservs = Listserv.page(params[:page])
  end

  def show
  end

  def new
    @listserv = Listserv.new
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
        :digest_header,
        :digest_footer,
        :send_digest,
        :digest_reply_to,
        :timezone,
        :banner_ad_override_id,
        :digest_description,
        :digest_send_day,
        :digest_query
      )
    end
end
