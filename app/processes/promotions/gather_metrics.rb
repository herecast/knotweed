module Promotions
  class GatherMetrics

    def self.call(*args)
      self.new(*args).call
    end

    def initialize(campaign)
      @campaign = campaign
    end

    def call
      if ['ROS', 'Sponsored', 'Targeted'].include?(@campaign.ad_promotion_type)
        @campaign.promotions.map do |promotion|
          {
            id: promotion.id,
            impression_count: reportable_impression_count(promotion),
            click_count: promotion.promotable.click_count
          }
        end
      elsif @campaign.ad_promotion_type == 'Digest'
        @campaign.promotions.map do |promotion|
          {
            id: promotion.id,
            impression_count: promotion.promotable.digest_opens,
            click_count: promotion.promotable.digest_clicks
          }
        end
      end
    end

    private

      def reportable_impression_count(promotion)
        if promotion.promotable.daily_max_impressions.present?
          impression_count = days_run(promotion) * promotion.promotable.daily_max_impressions
        else
          impression_count = days_run(promotion) * impressions_per_day
        end

        if promotion.promotable.impression_count < impression_count
          impression_count = promotion.promotable.impression_count
        end

        impression_count
      end

      def campaign_length
        (@campaign.ad_campaign_end - @campaign.ad_campaign_start).to_i + 1
      end

      def impressions_per_day
        (@campaign.ad_max_impressions.to_f / campaign_length.to_f).to_i
      end

      def promotion_length(promotion)
        (promotion.promotable.campaign_end - promotion.promotable.campaign_start).to_i + 1
      end

      def days_run(promotion)
        if promotion.promotable.campaign_end > Date.current
          (Date.current - promotion.promotable.campaign_start).to_i + 1
        else
          promotion_length(promotion)
        end
      end

  end
end