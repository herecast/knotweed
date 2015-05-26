module Api
  module V2

    class ContentsController < ApiController

      # pings the DSP to retrieve a related banner ad for a generic
      # content type.
      def related_promotion
        if params[:event_instance_id].present?
          ei = EventInstance.find params[:event_instance_id]
          @content = ei.event.content
        elsif params[:event_id].present?
          e = Event.find params[:event_id]
          @content = e.content
        end

        begin
          promoted_content_id = @content.get_related_promotion(@repository)
          new_content = Content.find promoted_content_id
        rescue
          new_content = nil
        end
        if new_content.nil?
          render json: {}
        else
          promo = new_content.promotions.where(active: true, promotable_type: 'PromotionBanner').first
          render json: 
            { 
              banner: promo.promotable.banner_image.url, 
              target_url: promo.promotable.redirect_url
            }
        end

      end

      def similar_content
        if params[:event_instance_id].present?
          ei = EventInstance.find params[:event_instance_id]
          @content = ei.event.content
        elsif params[:event_id].present?
          e = Event.find params[:event_id]
          @content = e.content
        end

        @contents = @content.similar_content(@repository)
        render json: @contents, each_serializer: SimilarContentSerializer,
          root: 'similar_content'

      end

    end

  end
end
