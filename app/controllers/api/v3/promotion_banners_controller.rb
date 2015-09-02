# of note, our consumer app actually uses this Api V2 endpoint through the consumer app 
# proxy (in addition to the ember app using it). The endpoint path is hard coded
# in javascript.
module Api
  module V3
    class PromotionBannersController < ApiController

      def track_click
        @banner = PromotionBanner.find params[:id]
        @banner.click_count += 1
        if @banner.save
          render json: @banner
        else
          render json: {}, status: 404
        end
      end

    end
  end
end
