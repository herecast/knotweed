# frozen_string_literal: true

class CampaignsController < ApplicationController
  def index
    @active = params[:promotion_banners_active] == 'on'
    if params[:reset]
      session[:campaign_search] = nil
      @active = false
    elsif params[:q].present? || @active == true
      params[:q] ||= {}
      params[:q].each { |key, val| params[:q][key] = '' if val == '0' }
      params[:q][:promotion_promotable_type_eq] = 'PromotionBanner'
      params[:q][:content_category_eq] = 'campaign'
      session[:campaign_search] = params[:q]
    end

    @search = Content.ransack(session[:campaign_search])

    if session[:campaign_search].present?
      @campaigns = @search.result(distinct: true)
                          .order('created_at DESC')
                          .page(params[:page])
                          .per(25)
                          .includes(:organization, promotions: [:promotable])
      @campaigns = @campaigns.ad_campaign_active if @active
    else
      @campaigns = []
    end
  end

  def new
    @content = Content.new
  end

  def create
    @content = Content.new(campaign_params.merge({
      pubdate: Date.current,
      content_category: 'campaign'
    }))
    if @content.save
      # create campaign on Subtext Ad Service
      BackgroundJob.perform_later('SubtextAdService', 'create', @content)
      flash[:notice] = 'Campaign created successfully!'
      redirect_to correct_path
    else
      render 'new'
    end
  end

  def edit
    @content = Content.find(params[:id])
  end

  def update
    @content = Content.find(params[:id])
    if @content.update_attributes(campaign_params)
      # update campaign on Subtext Ad Service (or create if `ad_service_id` not present)
      if @content.ad_service_id.present?
        BackgroundJob.perform_later('SubtextAdService', 'update', @content)
      else
        BackgroundJob.perform_later('SubtextAdService', 'create', @content)
      end
      flash[:notice] = 'Campaign updated successfully!'
      redirect_to correct_path
    else
      render 'edit'
    end
  end

  private

  def campaign_params
    params.require(:content).permit(
      :organization_id,
      :title,
      :subtitle,
      :authors,
      :pubdate,
      :ad_promotion_type,
      :ad_campaign_start,
      :ad_campaign_end,
      :ad_max_impressions,
      :sanitized_content,
      :ad_invoiced_amount,
      :ad_invoice_paid,
      :ad_commission_amount,
      :ad_commission_paid,
      :ad_services_amount,
      :ad_services_paid,
      :ad_sales_agent,
      :ad_promoter
    )
  end

  def correct_path
    params[:continue_editing].present? ? edit_campaign_path(@content) : campaigns_path
  end
end
