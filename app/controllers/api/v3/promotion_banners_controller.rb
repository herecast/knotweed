# of note, our consumer app actually uses this Api V2 endpoint through the consumer app 
# proxy (in addition to the ember app using it). The endpoint path is hard coded
# in javascript.
module Api
  module V3
    class PromotionBannersController < ApiController

      def track_click
        @content = Content.find params[:id] 
        if @content.present?
          @content.increment :banner_click_count
          @content.save
        else
          head :unprocessable_entity and return
        end

        render json: @content, serializer: ContentSerializer
      end

    end
  end
end
