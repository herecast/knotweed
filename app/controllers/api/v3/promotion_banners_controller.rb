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
        opts                   = {}
        opts[:limit]           = params[:limit] || 1
        opts[:exclude]         = params[:exclude]
        opts[:promotion_id]    = params[:promotion_id]
        opts[:content_id]      = params[:content_id]
        opts[:organization_id] = params[:organization_id]
        opts[:repository]      = @repository

        conditionally_prime_daily_ad_reports
        @promotion_banners = SelectPromotionBanners.call(opts)

        log_promotion_banner_loads(request.user_agent, request.remote_ip)
        @promotion_banners = @promotion_banners.map{ |promo| promo.first }

        render json:  @promotion_banners, root: :promotions,
          each_serializer: RelatedPromotionSerializer
      end

      def track_impression
        @banner = PromotionBanner.find params[:id]

        unless @current_api_user.try(:skip_analytics?)
          BackgroundJob.perform_later("RecordPromotionBannerMetric", "call", 'impression', @current_api_user, @banner, Date.current.to_s,
            content_id:  params[:content_id],
            gtm_blocked: params[:gtm_blocked] == 'true'
          )
        end

        render json: {}, status: :ok
      end

      def track_click
        # use find_by_id because we want a return of nil instead
        # of causing an exception with find
        @banner = PromotionBanner.find_by_id params[:promotion_banner_id]
        if @banner.present?
          unless @current_api_user.try(:skip_analytics?)
            BackgroundJob.perform_later("RecordPromotionBannerMetric", "call", 'click', @current_api_user, @banner, Date.current.to_s,
              content_id: params[:content_id]
            )

            @content = Content.find_by_id params[:content_id]
            if @content.present?
              BackgroundJob.perform_later('RecordContentMetric', 'call', @content, 'click', Date.current.to_s,
                user_id:    @current_api_user.try(:id)
              )
            end
          end
          render json: {}, status: :ok
        else
          head :unprocessable_entity and return
        end
      end

      def create_ad_metric
        ad_metric = AdMetric.new(ad_metric_params)
        if ad_metric.valid?
          ad_metric.save unless @current_api_user.try(:skip_analytics?)
          render json: {}, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      def show_promotion_coupon
        @promotion_coupon = PromotionBanner.find_by(id: params[:id])
        if @promotion_coupon.present? && @promotion_coupon.promotion_type == PromotionBanner::COUPON
          render json: @promotion_coupon, serializer: PromotionCouponSerializer
        else
          render json: {}, status: :not_found
        end
      end

      def create_promotion_coupon_email
        promotion_coupon = PromotionBanner.find_by(id: params[:id])
        if promotion_coupon.present?
          AdMailer.coupon_request(params[:email], promotion_coupon).deliver_later
          render json: {}, status: :ok
        else
          render json: {}, status: :bad_request
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

      def conditionally_prime_daily_ad_reports
        most_recent_reset_time = Rails.cache.fetch('most_recent_reset_time')
        if most_recent_reset_time.nil? || most_recent_reset_time < Date.current
          BackgroundJob.perform_later('PrimeDailyPromotionBannerReports', 'call', Date.current.to_s)
          Rails.cache.write('most_recent_reset_time', Time.current, expires_in: 24.hours)
        end
      end

      def log_promotion_banner_loads(user_agent, user_ip)
        unless @current_api_user.try(:skip_analytics?)
          @promotion_banners.each do |promotion_banner|
            BackgroundJob.perform_later("RecordPromotionBannerMetric", "call", 'load', @current_api_user, promotion_banner[0], Date.current.to_s,
              content_id:    params[:content_id],
              select_score:  promotion_banner[1],
              select_method: promotion_banner[2],
              user_agent:    user_agent,
              user_ip:       user_ip
            )
          end
        end
      end

      def ad_metric_params
        params.require(:ad_metric).permit(
          :campaign,
          :event_type,
          :page_url,
          :content
        )
      end

    end
  end
end
