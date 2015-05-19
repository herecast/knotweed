module Api
  module V2

    class ContentsController < ApiController

      # pings the DSP to retrieve a related banner ad for a generic
      # content type.
      def related_promotion
        if params[:event_instance_id].present?
          ei = EventInstance.find params[:event_instance_id]
          root = ei.event.content
        elsif params[:event_id].present?
          e = Event.find params[:event_id]
          root = e.content
        end

        @repo = Repository.find params[:repository_id]

        begin
          promoted_content_id = root.get_related_promotion(@repo)
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
              target_url: promo.promotable.redirect_url, 
              content_id: new_content.id 
            }
        end

      end

    end

  end
end
