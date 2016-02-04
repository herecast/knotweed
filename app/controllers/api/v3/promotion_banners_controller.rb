module Api
  module V3
    class PromotionBannersController < ApiController

      def track_click
        # use find_by_id because we want a return of nil instead
        # of causing an exception with find
        @content = Content.find_by_id params[:content_id] 
        @banner = PromotionBanner.find_by_id params[:promotion_banner_id]
        if @content.present? and @banner.present? and !@current_api_user.try(:skip_analytics?)
          @content.increment_integer_attr! :banner_click_count
          @banner.increment_integer_attr! :click_count
        else
          head :unprocessable_entity and return
        end
        head :ok
      end

      def metrics
        @promotion_banner = PromotionBanner.find(params[:id])
        # confirm user owns content first
        if @current_api_user != @promotion_banner.promotion.created_by 
          render json: { errors: ['You do not have permission to access these metrics.'] }, 
            status: 401
        else
          render json: @promotion_banner, serializer: PromotionBannerMetricsSerializer
        end
      end

    end
  end
end
