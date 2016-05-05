module Api
  module V3
    class PromotionBannersController < ApiController
      before_filter :check_logged_in!, only: :index

      def index
        params[:sort] ||= 'click_count DESC'
        params[:page] ||= 1
        params[:per_page] ||= 12

        @promotion_banners = PromotionBanner.joins(:promotion => :content).
       #   where('promotions.created_by = ? and promotable_type = "PromotionBanner"', @current_api_user.id).
          order(sanitize_sort_parameter(params[:sort])).
          page(params[:page].to_i).per(params[:per_page].to_i)

        render json: @promotion_banners, each_serializer: PromotionBannerSerializer
      end
      
      def track_click
        # use find_by_id because we want a return of nil instead
        # of causing an exception with find
        @content = Content.find_by_id params[:content_id] 
        @banner = PromotionBanner.find_by_id params[:promotion_banner_id]
        if @content.present? and @banner.present?# and !@current_api_user.try(:skip_analytics?)
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
       # if @current_api_user != @promotion_banner.promotion.created_by 
         # render json: { errors: ['You do not have permission to access these metrics.'] }, 
           # status: 401
       # else
          render json: @promotion_banner, serializer: PromotionBannerMetricsSerializer, context: 
            {start_date: params[:start_date], end_date: params[:end_date]}
       # end
      end

      protected

      def sanitize_sort_parameter(sort)
        sort_parts = sort.split(',')
        sort_parts.select! do |pt|
          pt.match /\A([a-zA-Z]+_)?[a-zA-Z]+ (ASC|DESC)/
        end
        sort_parts.join(',').gsub(/(pubdate|title)/,'contents.\1').gsub('view_count','impression_count')
      end

    end
  end
end
