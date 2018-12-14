class ListservCampaignsController < ApplicationController
  before_action :authorize_access!

  def create
    @campaign = listserv.campaigns.build campaign_params

    if @campaign.save
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  def update
    @campaign = listserv.campaigns.find params[:id]

    if @campaign.update campaign_params
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  def destroy
    @campaign = listserv.campaigns.find params[:id]

    if @campaign.destroy
      render status: :ok
    else
      #:nocov:
      render status: :unprocessable_entity
      #:nocov:
    end
  end

  protected

  def listserv
    Listserv.find(params[:listserv_id])
  end

  def campaign_params
    params.require(:campaign).permit(
      :sponsored_by,
      :digest_query,
      :title,
      :preheader,
      :promotions_list,
      community_ids: [],
      promotion_ids: [],
    ).tap do |p|
      if p[:community_ids].respond_to?(:[])
        p[:community_ids].reject! { |c| c.empty? }
      end
    end
  end
end
