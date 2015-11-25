# of note, our consumer app actually uses this Api V2 endpoint through the consumer app 
# proxy (in addition to the ember app using it). The endpoint path is hard coded
# in javascript.
module Api
  module V3
    class PromotionBannersController < ApiController
      after_filter :event_track

      def track_click
        # use find_by_id because we want a return of nil instead
        # of causing an exception with find
        @content = Content.find_by_id params[:content_id] 
        @banner = PromotionBanner.find_by_id params[:promotion_banner_id]
        if @content.present? && @banner.present?
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

      private

      def event_track
        props = {}
        props.merge! @tracker.navigation_properties(@content.try(:channel_type), nil, url_for, params)
        props.merge! @tracker.content_properties(@content)
        props.merge! @tracker.banner_properties(@banner)

        @tracker.track(@mixpanel_distinct_id, 'clickBannerAd', @current_api_user, props)
      end

    end
  end
end
