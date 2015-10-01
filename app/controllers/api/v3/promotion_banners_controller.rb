# of note, our consumer app actually uses this Api V2 endpoint through the consumer app 
# proxy (in addition to the ember app using it). The endpoint path is hard coded
# in javascript.
module Api
  module V3
    class PromotionBannersController < ApiController

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

    end
  end
end
