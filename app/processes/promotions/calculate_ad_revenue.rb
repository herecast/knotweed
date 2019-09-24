module Promotions
  class CalculateAdRevenue
    def self.call(*args)
      self.new(*args).call
    end

    def initialize(campaign, start_date, end_date)
      @campaign = campaign
      @start_date = start_date
      @end_date = end_date
    end

    def call
      rev_per_day = @campaign.ad_invoiced_amount / ((@campaign.ad_campaign_end - @campaign.ad_campaign_start).to_i + 1)

      if @campaign.ad_campaign_end > @start_date && @campaign.ad_campaign_start < @end_date
        if @campaign.ad_campaign_end >= @end_date
          end_for_calc = @end_date
        else
          end_for_calc = @campaign.ad_campaign_end
        end

        if @campaign.ad_campaign_start <= @start_date
          start_for_calc = @start_date
        else
          start_for_calc = @campaign.ad_campaign_start
        end

        days_run = (end_for_calc - start_for_calc).to_i + 1
      else
        days_run = 0
      end

      total_rev = rev_per_day * days_run
      total_rev
    end
  end
end
