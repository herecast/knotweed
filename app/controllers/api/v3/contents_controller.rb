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

      def index
        opts = {}
        opts = { select: '*, weight()', 
                 excerpts: { limit: 350, around: 5, html_strip_mode: "strip" } }
        opts[:order] = 'pubdate DESC'
        opts[:with] = {}
        opts[:conditions] = {}
        opts[:page] = params[:page] || 1
        opts[:conditions][:published] = 1 if @repository.present?
        opts[:sql] = { include: [:images, :publication, :root_content_category] }

        default_location_id = Location.find_by_city(Location::DEFAULT_LOCATION).id
        location_condition = @current_api_user.try(:location_id) || default_location_id

        root_news_cat = ContentCategory.find_by_name 'news'
        news_opts = opts.merge({ 
          with: { 
            root_content_category_id: root_news_cat.id,
            all_loc_ids: [location_condition]
          },
          per_page: 2
        })

        # is this slower than a single query that retrieves all 4 using 'name IN (...)'?
        # I doubt it.
        reg_cat_ids = [ContentCategory.find_by_name('market').id,
                       ContentCategory.find_by_name('event').id]
        # if signed in, include talk.
        if @current_api_user.present?
          reg_cat_ids += [ContentCategory.find_by_name('talk_of_the_town').id]
        end

        reg_opts = opts.merge({
          with: { 
            loc_ids: [location_condition],
            root_content_category_id: reg_cat_ids
          },
          per_page: 12
        })


        news_contents = Content.search news_opts
        reg_contents = Content.search reg_opts

        # note: can't combine these two relations without converting them to arrays
        # because thinking sphinx
        @contents = news_contents.to_a + reg_contents.to_a

        render json: @contents, arrayserializer: ContentSerializer

      end

    end
  end
end
