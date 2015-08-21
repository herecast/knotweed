module Api
  module V3
    class ContentsController < ApiController
      before_filter :check_logged_in!, only:  [:moderate]
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
          promoted_content = Content.find promoted_content_id
        rescue
          promoted_content = nil
        end
        if promoted_content.nil?
          render json: {}
        else
          @banner = PromotionBanner.for_content(promoted_content.id).active.first
          unless @banner.present? # banner must've expired or been used up since repo last updated
            # so we need to trigger repo update
            PromotionBanner.remove_promotion(@repo, promoted_content.id)
            render json: {}
          else
            ContentPromotionBannerImpression.log_impression(@content.id, @banner.id)
            @banner.impression_count += 1
            @banner.save
            render json:  { related_promotion:
              { 
                image_url: @banner.banner_image.url, 
                redirect_url: @banner.redirect_url,
                banner_id: @banner.id
              }
            }
          end
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

        @contents = @content.similar_content(@repository, 20)

        # filter by publication
        if @requesting_app.present?
          @contents.select!{ |c| @requesting_app.publications.include? c.publication }
        end

        # This is a Bad temporary hack to allow filtering the sim stack provided by apiv2
        # the same way that the consumer app filters it. 
        if Figaro.env.respond_to? :sim_stack_categories
          @contents.select! do |c|
            Figaro.env.sim_stack_categories.include? c.content_category.name
          end
        end

        @contents = @contents.slice(0,6)

        render json: @contents, each_serializer: SimilarContentSerializer,
          root: 'similar_content', consumer_app_base_uri: @requesting_app.try(:uri)

      end

      def moderate
        content = Content.find(params[:id])
        ModerationMailer.send_moderation_flag_v2(content, params[:flag_type], \
          @current_api_user).deliver
        head :no_content
      end
    end
  end
end
