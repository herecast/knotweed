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

      private

      def event_track
        props = {}
        #nav props
        props['channelName'] = @content.try(:channel_type)
        props['url'] = url_for

        #content props
        props['contentId'] = @content.try(:id)
        props['contentChannel'] = @content.try(:channel_type)
        props['contentLocation'] = @content.try(:location)
        props['contentPubdate'] = @content.try(:pubdate)
        props['contentTitle'] = @content.try(:title)
        props['contentPublicatio'] = @content.try(:publication).try(:name)
        
        #banner props
        props['bannerAdId'] = @banner.try(:id)
        props['bannerUrl'] = @banner.try(:redirect_url)
        
        @tracker.track(@current_api_user.try(:id), 'clickBannerAd', @current_api_user, props)
      end

    end
  end
end
