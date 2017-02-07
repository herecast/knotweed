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
    organization = Organization.find(params[:organization_id])
    # as of now, we are not allowing creation of promotions without
    # pre-specifying the content, so if params[:content_id] is nil,
    # redirect back from whence they came
    if params[:content_id].present?
      content = Content.find(params[:content_id]) unless params[:content_id].nil?
      @promotion = Promotion.new organization: organization
      @promotion.content = content unless content.nil?
      if params[:promotable_type].present?
        if params[:promotable_type] == 'PromotionBanner'
          @promotion.promotable = PromotionBanner.new
        elsif params[:promotable_type] == 'PromotionListserv'
          @promotion.promotable = PromotionListserv.new
        end
      end

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @promotion }
      end
    else
      flash[:notice] = "Can't create a promotion with no content"
      redirect_to edit_organization_path(organization)
    end
  end

  def edit
    @promotion = Promotion.find(params[:id])
  end

  def create
    @promotion = Promotion.new(promotion_params)

    pub = Organization.find params[:organization_id]
    @promotion.organization = pub

    respond_to do |format|
      if @promotion.save
        format.html { redirect_to @promotion, notice: 'Promotion was successfully created.' }
        format.json { render json: @promotion, status: :created, location: @promotion }
      else
        format.html { render 'new', error: @promotion.errors.messages }
        format.json { render json: @promotion.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @promotion = Promotion.find(params[:id])

    respond_to do |format|
      if @promotion.update_attributes(promotion_params)
        format.html { redirect_to @promotion, notice: 'Promotion was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @promotion.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    def promotion_params
      params.require(:promotion).permit(
        :description,
        :organization_id,
        :content_id,
        :promotable_type,
        :paid,
        promotable_attributes: [ :id, :boost, :campaign_start, :campaign_end, :daily_max_impressions,
          :max_impressions, :banner_image, :redirect_url, :promotion_type,
          :cost_per_impression, :cost_per_day, :coupon_email_body, :coupon_image ]
      )
    end

end
