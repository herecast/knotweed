module Api
  module V3
    class PromotionBannersController < ApiController
      before_filter :check_logged_in!, only: :index

      def index
        params[:sort] ||= 'click_count DESC'
        params[:page] ||= 1
        params[:per_page] ||= 12

        scope = PromotionBanner.joins(promotion: :content)

        if params[:organization_id].present?
          org = Organization.find params[:organization_id]
          if current_ability.can? :manage, org
            scope = scope.where('contents.organization_id = ?', org.id)
          else
            head :no_content and return
          end
        else
          scope = scope.where('promotions.created_by = ?', @current_api_user.id)
        end
        @promotion_banners = scope.order(sanitize_sort_parameter(params[:sort])).
          page(params[:page].to_i).per(params[:per_page].to_i)

        render json: @promotion_banners, each_serializer: PromotionBannerSerializer
      end

      def show
        if params[:content_id].present?
          @content = Content.find params[:content_id]
          # get related promo if exists
          @banner, select_score, select_method = @content.get_related_promotion(@repository)
        elsif params[:organization_id].present?
          @organization = Organization.find params[:organization_id]
          @banner, select_score, select_method = @organization.get_promotion
        else
          @banner, select_score, select_method = PromotionBanner.get_random_promotion
        end

        unless @banner.present? # banner must've expired or been used up since repo last updated
          render json: {}
        else
          # log banner ad impression with associated details
          ContentPromotionBannerImpression.log_impression(@content.try(:id), @banner.id,
                                                          select_method, select_score)
          # increment promotion_banner counts for impressions and daily_impressions
          unless @current_api_user.try(:skip_analytics?)
            @banner.increment_integer_attr! :impression_count
            @banner.increment_integer_attr! :daily_impression_count
          end

          render json:  @banner, root: :promotion,
            serializer: RelatedPromotionSerializer
        end
      end
      
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
          render json: @promotion_banner, serializer: PromotionBannerMetricsSerializer, context: 
            {start_date: params[:start_date], end_date: params[:end_date]}
        end
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
