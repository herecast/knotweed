module Api
  module V3
    class PromotionBannerReportSerializer < ActiveModel::Serializer
      # apologies for the naming -- this uses promotion banner objects to combine all promotion banner reports
      # from a given date range into a single JSON object
      
      attributes :type, :promo_id, :banner_id, :campaign_start, :campaign_end,
        :served, :cost, :daily_cost, :daily_max, :clicks, :ctr, :client, :banner,
        :daily_reports

      def type; object.promotion_type; end
      def promo_id; object.promotion.id; end
      def banner_id; object.id; end
      def campaign_start; object.campaign_start.try(:strftime,"%D"); end
      def campaign_end; object.campaign_end.try(:strftime,"%D"); end
      def served; object.impression_count; end
      def cost; object.cost_per_impression; end
      def daily_cost; object.cost_per_day; end
      def daily_max; object.daily_max_impressions; end
      def clicks; object.click_count; end
      def ctr; "%.2f" % (object.click_count * 100.0 / object.impression_count); end
      def client; object.promotion.try(:organization).try(:name); end
      def banner; object.promotion.try(:content).try(:title); end

      def daily_reports
        # we need to have a date entry for every date in the range, so generating
        # this hash rather than mapping directly from promotion_banner_reports
        #
        # TODO: this works because Javascript just reads the keys from this object in order,
        # at least in GOogle sheets, but to make it more robust, we should adjust this -- and
        # the Javascript parsing code in Google Sheets -- to use an array so that date order is
        # guaranteed
        output_hash = {}
        date = context[:end_date]
        while(date >= context[:start_date])
          output_hash[date.strftime("%D")] = 0
          date -= 1.day
        end
        object.promotion_banner_reports.each do |pbr|
          # this might seem redundant -- iterating through pbrs we're not using -- 
          # but because the original query "includes" promotion_banner_reports, this actually
          # saves us from an n+1 query
          if output_hash.has_key? pbr.report_date.strftime("%D")
            output_hash[pbr.report_date.strftime("%D")] = pbr.impression_count
          end
        end
        output_hash
      end

    end
  end
end
