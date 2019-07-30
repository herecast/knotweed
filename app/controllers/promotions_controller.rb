# frozen_string_literal: true

class PromotionsController < ApplicationController
  def index
    @organization = Organization.find(params[:organization_id])
    @promotions = @organization.promotions

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @promotions }
    end
  end

  def show
    @promotion = Promotion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @promotion }
    end
  end

  def new
    # as of now, we are not allowing creation of promotions without
    # pre-specifying the content, so if params[:content_id] is nil,
    # redirect back from whence they came
    if params[:content_id].present?
      content = Content.find(params[:content_id]) unless params[:content_id].nil?
      @promotion = Promotion.new content: content
      if params[:promotable_type].present?
        if params[:promotable_type] == 'PromotionBanner'
          @promotion.promotable = PromotionBanner.new
        end
      end

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @promotion }
      end
    else
      flash[:notice] = "Can't create a promotion with no content"
      redirect_to edit_organization_path(params[:organization_id])
    end
  end

  def edit
    @promotion = Promotion.find(params[:id])
  end

  def create
    @promotion = Promotion.new(promotion_params)
    if @promotion.save
      if @promotion.promotable_type == 'PromotionBanner'
        BackgroundJob.perform_later('SubtextAdService', 'add_creative', @promotion.promotable)
      end
      respond_to do |format|
        format.html { redirect_to edit_campaign_path(@promotion.content), notice: 'Promotion was successfully created.' }
        format.json { render json: @promotion, status: :created, location: @promotion }
      end
    else
      respond_to do |format|
        format.html { render 'new', error: @promotion.errors.messages }
        format.json { render json: @promotion.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @promotion = Promotion.find(params[:id])

    respond_to do |format|
      if @promotion.update_attributes(promotion_params)
        if @promotion.promotable_type == 'PromotionBanner'
          if @promotion.promotable.ad_service_id.present? # already exists, so update
            BackgroundJob.perform_later('SubtextAdService', 'update_creative', @promotion.promotable)
          else
            BackgroundJob.perform_later('SubtextAdService', 'add_creative', @promotion.promotable)
          end
        end

        format.html { redirect_to edit_campaign_path(@promotion.content), notice: 'Promotion was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @promotion.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def promotion_params
    params.require(:promotion).permit(
      :description,
      :content_id,
      :promotable_type,
      :paid,
      promotable_attributes: %i[
        id
        boost
        campaign_start
        campaign_end
        daily_max_impressions
        max_impressions
        banner_image
        redirect_url
        promotion_type
        sales_agent
        cost_per_impression
        cost_per_day
        coupon_email_body
        coupon_image
        remove_coupon_image
        remove_banner_image
        location_id
      ],
      content_attributes: [:title]
    )
  end
end
