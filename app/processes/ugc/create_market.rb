module Ugc
  class CreateMarket
    def self.call(*args)
      self.new(*args).call
    end

    def initialize(params, remote_ip: nil, user_scope:)
      @current_user = user_scope
      @params = params
      @remote_ip = remote_ip
    end

    def call
      @market_post = MarketPost.new(market_post_params.deep_merge(
        content_attributes: {
          created_by: @current_user,
          origin: Content::UGC_ORIGIN
        }
      ))

      update_locations @market_post

      @market_post.save

      conditionally_schedule_outreach_email

      @market_post.content
    end

    private

      def market_post_params
        new_params = @params.dup
        attributes = additional_create_attributes
        new_params[:content].merge!(attributes)

        new_params.delete(:location_id)

        new_params.require(:content).permit(
          :contact_email,
          :contact_phone,
          :contact_url,
          :cost,
          :latitude,
          :longitude,
          :locate_address,
          :locate_include_name,
          :locate_name,
          :status,
          :prefered_contact_method,
          :sold,
          content_attributes: [
            :id,
            :title,
            :raw_content,
            :biz_feed_public,
            :authoremail,
            :authors,
            :content_category_id,
            :pubdate,
            :timestamp,
            :organization_id,
            :my_town_only,
            :promote_radius,
            :ugc_job,
            :published,
            location_ids: [],
          ]
        )
      end

      def additional_create_attributes
        {
          cost: @params[:content][:cost],
          content_attributes: {
            title: @params[:content][:title],
            raw_content: @params[:content][:content],
            biz_feed_public: @params[:content][:biz_feed_public],
            authoremail: @current_user.try(:email),
            authors: @current_user.try(:name),
            content_category_id: market_category.id,
            pubdate: Time.zone.now,
            published: true,
            timestamp: Time.zone.now,
            organization_id: @params[:content][:organization_id] || dailyuv_org.id,
            ugc_job: @params[:content][:ugc_job]
          }
        }
      end

      def market_category
        ContentCategory.find_or_create_by(name: 'market')
      end

      def dailyuv_org
        Organization.find_or_create_by(name: 'From DailyUV')
      end

      def location_params
        @params[:content].slice(:promote_radius, :location_id)
      end

      def update_locations post
        if location_params[:promote_radius].present? &&
            location_params[:location_id].present?

          UpdateContentLocations.call post.content,
            promote_radius: location_params[:promote_radius].to_i,
            base_locations: [Location.find_by_slug_or_id(location_params[:location_id])]
        end
      end

      def conditionally_schedule_outreach_email
        if @current_user.contents.market_posts.count == 1
          BackgroundJob.perform_later('Outreach::CreateUserHookCampaign', 'call',
            user: @current_user,
            type: 'market_post'
          )
        end
      end

  end
end
