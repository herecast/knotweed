module Api
  module V3
    class PromotionBannersController < ApiController
      def show
        opts                   = {}
        opts[:limit]           = params[:limit] || 1
        opts[:exclude]         = params[:exclude]
        opts[:promotion_id]    = params[:promotion_id]
        opts[:content_id]      = params[:content_id]
        opts[:organization_id] = params[:organization_id]

        conditionally_prime_daily_ad_reports
        @selected_promotion_banners = SelectPromotionBanners.call(opts)

        render json: @selected_promotion_banners, root: :promotions,
               each_serializer: SelectedPromotionSerializer
      end

      def track_impression
        @banner = PromotionBanner.find params[:id]
        if @banner.present?
          record_promotion_banner_metric(@banner, 'impression')
          render json: {}, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      def track_load
        # use find_by_id because we want a return of nil instead
        # of causing an exception with find
        @banner = PromotionBanner.find_by_id params[:promotion_banner_id]
        if @banner.present?
          record_promotion_banner_metric(@banner, 'load')

          render json: {}, status: :ok
        else
          head :unprocessable_entity and return
        end
      end

      def track_click
        # use find_by_id because we want a return of nil instead
        # of causing an exception with find
        @banner = PromotionBanner.find_by_id params[:promotion_banner_id]
        if @banner.present?
          record_promotion_banner_metric(@banner, 'click')
          record_content_metric('click')
          render json: {}, status: :ok
        else
          head :unprocessable_entity and return
        end
      end

      def create_ad_metric
        ad_metric = AdMetric.new(ad_metric_params)
        if ad_metric.valid?
          ad_metric.save unless analytics_blocked?
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
        authorize! :manage, @promotion_banner
        render json: @promotion_banner, serializer: PromotionBannerMetricsSerializer, context:
          { start_date: params[:start_date], end_date: params[:end_date] }
      end

      protected

      def sanitize_sort_parameter(sort)
        sort_parts = sort.split(',')
        sort_parts.select! do |pt|
          pt.match /\A([a-zA-Z]+_)?[a-zA-Z]+ (ASC|DESC)/
        end
        sort_parts.join(',').gsub(/(pubdate|title)/, 'contents.\1').gsub('view_count', 'impression_count')
      end

      def sanitize_start_date_sort(sort)
        sort_parts = sort.split(',')
        sort_direction = sort_parts.last
        if sort_direction.include?('ASC')
          "campaign_start ASC"
        elsif sort_direction.include?('DESC')
          "campaign_start DESC"
        end
      end

      def conditionally_prime_daily_ad_reports
        most_recent_reset_time = Rails.cache.fetch('most_recent_reset_time')
        if most_recent_reset_time.nil? || most_recent_reset_time < Date.current
          is_prod = (ENV['STACK_NAME'] == "knotweed-production")
          BackgroundJob.perform_later('PrimeDailyPromotionBannerReports', 'call', Date.current.to_s, is_prod)
          Rails.cache.write('most_recent_reset_time', Time.current, expires_in: 24.hours)
        end
      end

      def record_promotion_banner_metric(promotion_banner, event_type)
        unless analytics_blocked?
          data = {
            content_id: params[:content_id],
            event_type: event_type,
            current_date: Date.current.to_s,
            user_id: current_user.try(:id),
            client_id: params[:client_id],
            promotion_banner_id: promotion_banner.id,
            select_score: params[:select_score],
            select_method: params[:select_method],
            load_time: params[:load_time],
            user_agent: request.user_agent,
            user_ip: request.remote_ip,
            gtm_blocked: params[:gtm_blocked] == true,
            page_placement: params[:page_placement],
            page_url: params[:page_url]
          }

          if params[:location_id].present?
            location = Location.find_by_slug_or_id(params[:location_id])
            data[:location_id] = location.try(:id)
            data[:location_confirmed] = ['1', 1, 'true', true].include?(params[:location_confirmed])
          end

          BackgroundJob.perform_later('RecordPromotionBannerMetric', 'call', data)
        end
      end

      def record_content_metric(event_type)
        unless analytics_blocked?
          @content = Content.find_by_id params[:content_id]
          if @content.present?
            opts = {
              event_type: event_type,
              current_date: Date.current.to_s,
              user_id: current_user.try(:id),
              client_id: params[:client_id]
            }.tap do |data|
              if params[:location_id].present?
                data[:location_id] = Location.find_by_slug_or_id(params[:location_id]).try(:id)
              end
            end

            BackgroundJob.perform_later('RecordContentMetric', 'call', @content, opts)
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
