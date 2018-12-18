# frozen_string_literal: true

class RecordPromotionBannerMetric
  def self.call(*args)
    new(*args).call
  end

  def initialize(opts = {})
    @opts             = opts
    @promotion_banner = PromotionBanner.find(opts[:promotion_banner_id])
    @current_date     = opts[:current_date].to_date
  end

  def call
    record_event
    find_or_create_promotion_banner_report
    increment_report_stats
  end

  private

  def record_event
    PromotionBannerMetric.create!(
      content_id: @opts[:content_id],
      event_type: @opts[:event_type],
      user_id: @opts[:user_id],
      client_id: @opts[:client_id],
      location_id: @opts[:location_id],
      location_confirmed: @opts[:location_confirmed] || false,
      promotion_banner_id: @opts[:promotion_banner_id],
      select_score: @opts[:select_score],
      select_method: @opts[:select_method],
      load_time: @opts[:load_time],
      user_agent: @opts[:user_agent],
      user_ip: @opts[:user_ip],
      gtm_blocked: @opts[:gtm_blocked],
      page_placement: @opts[:page_placement],
      page_url: @opts[:page_url]
    )
  end

  def find_or_create_promotion_banner_report
    @report = @promotion_banner.find_or_create_daily_report(@current_date)
  end

  def increment_report_stats
    case @opts[:event_type]
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
