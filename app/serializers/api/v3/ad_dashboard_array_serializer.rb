module Api
  module V3
    class AdDashboardArraySerializer < ActiveModel::ArraySerializer

      def serializer_for(item)
        if item.is_a? PromotionBanner
          serializer = DashboardPromotionBannerSerializer
        else
          serializer = DashboardContentSerializer
        end
        serializer.new(item, scope: scope, key_format: key_format, context: @context, 
                       only: @only, except: @except, polymorphic: @polymorphic, 
                       namespace: @namespace)
      end

    end
  end
end
