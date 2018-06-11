module Api
  module V3
    class Contents::PromotionsController < ApiController

      def index
        content = Content.find(params[:content_id])
        if content.promotions.present?
          render json: content.promotions.shares
        else
          render json: []
        end
      end

      def create
        content = Content.find(params[:content_id])
        @promotion = content.promotions.build(promotion_params)
        if @promotion.save
          render json: @promotion, status: :created
        else
          render json: @promotion.errors, status: :unprocessable_entity
        end
      end

      private

        def promotion_params
          params.require(:promotion).permit(
            :created_by,
            :share_platform
          ).tap do |p|
            if p[:created_by].present?
              p[:created_by] = current_user
            end
          end
        end

    end
  end
end