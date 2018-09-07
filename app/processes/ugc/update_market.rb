module Ugc
  class UpdateMarket
    def self.call(*args)
      self.new(*args).call
    end

    def initialize(content, params, remote_ip: nil, user_scope:)
      @current_user = user_scope
      @params = params
      @remote_ip = remote_ip
      @content = content
    end

    def call
      @market_post = @content.channel

      update_locations @market_post

      @market_post.update market_post_params

      @market_post.content
    end

    private

      def market_post_params
        new_params = @params.dup
        attributes = additional_update_attributes
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
            :authoremail,
            :authors,
            :biz_feed_public,
            :content_category_id,
            :pubdate,
            :timestamp,
            :organization_id,
            :my_town_only,
            :promote_radius,
            :sunset_date,
            location_ids: []
          ]
        )
      end

      def additional_update_attributes
        {
          cost: @params[:content][:cost],
          content_attributes: {
            id: @params[:id],
            biz_feed_public: @params[:content][:biz_feed_public],
            title: @params[:content][:title],
            raw_content: @params[:content][:content],
            promote_radius: @params[:content].delete(:promote_radius)
          }
        }
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
  end
end
