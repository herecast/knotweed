class CampaignsController < ApplicationController

  def index
    @active = params[:promotion_banners_active] == 'on' ? true : false
    if params[:reset]
      session[:campaign_search] = nil
      @active = false
    else
      params[:q] ||= {}
      params[:q].each { |key, val| params[:q][key] = '' if val == '0' }
      params[:q][:promotion_promotable_type_eq] = 'PromotionBanner'
      session[:campaign_search] = params[:q]
    end

    @search = PromotionBanner.ransack(session[:campaign_search])

    if session[:campaign_search].present?
      @campaigns = @search.result(distinct: true)
        .order("created_at DESC")
        .page(params[:page])
        .per(25)
        .accessible_by(current_ability)
        .includes(promotion: [:content, :organization])
      @campaigns = @campaigns.active if @active
    else
      @campaigns = []
    end
  end
end
