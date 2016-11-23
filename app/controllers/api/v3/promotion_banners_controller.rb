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
        if params[:promotion_id].present?
          @banner = Promotion.where(promotable_type: 'PromotionBanner').find(params[:promotion_id]).promotable
          select_score, select_method = nil, 'sponsored content'
        elsif params[:content_id].present?
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
          report_promotion_banner_metric('load',
            content_id: params[:content_id],
            select_method: select_method,
            select_score: select_score
          )

          unless @current_api_user.try(:skip_analytics?)
            @banner.increment_integer_attr! :load_count
            ContentPromotionBannerLoad.log_load(@content.try(:id), @banner.id,
                                                            select_method, select_score)

            logger.info "[Load count incremented for]: #{@banner.inspect}"
          end

          render json:  @banner, root: :promotion,
            serializer: RelatedPromotionSerializer
        end
      end

      def track_impression
        @banner = PromotionBanner.find params[:id]
        report_promotion_banner_metric('impression', content_id: params[:content_id])

        # increment promotion_banner counts for impressions and daily_impressions
        unless @current_api_user.try(:skip_analytics?)
          @banner.increment_integer_attr! :impression_count
          @banner.increment_integer_attr! :daily_impression_count

          logger.info "[Impression count incremented for]: #{@banner.inspect}"
        end

        head :ok
      end

      def track_click
        # use find_by_id because we want a return of nil instead
        # of causing an exception with find
        @banner = PromotionBanner.find_by_id params[:promotion_banner_id]
        if @banner.present?
          report_promotion_banner_metric('click', content_id: params[:content_id])
          
          unless @current_api_user.try(:skip_analytics?)
            @banner.increment_integer_attr! :click_count
            @content = Content.find_by_id params[:content_id]
            @content.increment_integer_attr! :banner_click_count if @content.present?
          end
          render json: {}, status: :ok
        else
          head :unprocessable_entity and return
        end
      end

      def metrics
        @promotion_banner = PromotionBanner.find(params[:id])
        # confirm user owns content first
        if promo_created_by_user? or user_can_manage?
          render json: @promotion_banner, serializer: PromotionBannerMetricsSerializer, context: 
            {start_date: params[:start_date], end_date: params[:end_date]}
        else
          render json: { errors: ['You do not have permission to access these metrics.'] }, 
            status: 401
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

      def promo_created_by_user?
        @current_api_user == @promotion_banner.promotion.created_by
      end

      def user_can_manage?
        @current_api_user.ability.can?(:manage, @promotion_banner.promotion.organization)
      end

      def report_promotion_banner_metric(type, opts=nil)
        PromotionBannerMetric.create(
          event_type: type,
          promotion_banner_id: @banner.id,
          user_id: @current_api_user.try(:id),
          content_id: opts[:content_id],
          select_method: opts[:select_method],
          select_score: opts[:select_score]
        )
      end
    end
  end
end
