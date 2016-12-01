class RecordPromotionBannerMetric

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(event_type, user, promotion_banner, current_date, opts={})
    @event_type       = event_type
    @user             = user
    @promotion_banner = promotion_banner
    @current_date     = current_date.to_date
    @opts             = opts
  end

  def call
    record_event
    create_or_update_promotion_banner_report
    increment_report_stats
  end

  private

    def record_event
      PromotionBannerMetric.create!(
        event_type: @event_type,
        promotion_banner_id: @promotion_banner.id,
        user_id: @user.try(:id),
        content_id: @opts[:content_id],
        select_method: @opts[:select_method],
        select_score: @opts[:select_score]
      )
    end

    def create_or_update_promotion_banner_report
      @report = PromotionBannerReport.where(promotion_banner_id: @promotion_banner.id)
        .where("report_date >= ?", @current_date)
        .take

      unless @report.present?
        @report = PromotionBannerReport.create!(
          promotion_banner_id: @promotion_banner.id,
          report_date: @current_date
        )

        reset_promotion_banner_daily_impression_count
      end
    end

    def reset_promotion_banner_daily_impression_count
      @report.promotion_banner.update_attribute(:daily_impression_count, 0)
    end

    def increment_report_stats
      case @event_type
      when 'load'
        @report.increment!(:load_count)
        @promotion_banner.increment!(:load_count)
      when 'impression'
        @report.increment!(:impression_count)
        @promotion_banner.increment!(:impression_count)
        @promotion_banner.increment!(:daily_impression_count)
      when 'click'
        @report.increment!(:click_count)
        @promotion_banner.increment!(:click_count)
      end
    end

end