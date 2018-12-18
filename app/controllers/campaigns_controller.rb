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
      params[:q][:content_category_id_eq] = ContentCategory.find_or_create_by(name: 'campaign').id
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
    @content = Content.new(campaign_params)
    @content.content_category_id = campaign_content_category_id
    if @content.save
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

  def campaign_content_category_id
    ContentCategory.find_or_create_by(name: 'campaign').id
  end

  def correct_path
    params[:continue_editing].present? ? edit_campaign_path(@content) : campaigns_path
  end
end
