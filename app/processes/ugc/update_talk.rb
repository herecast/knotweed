module Ugc
  class UpdateTalk
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
      manage_location_attributes @content.channel

      @content.update talk_update_params
      @content
    end

    protected
      def talk_update_params
        new_params = ActionController::Parameters.new(
          content: @params[:content]
        )
        new_params[:content][:raw_content] = new_params[:content].delete(:content)
        new_params.require(:content).permit(
          :title,
          :biz_feed_public,
          :raw_content,
          :promote_radius
        )
      end

      def location_params
        @params[:content].slice(:promote_radius, :location_id)
      end

      def manage_location_attributes talk
        if location_params[:promote_radius].present? &&
            location_params[:location_id].present?

          UpdateContentLocations.call talk.content,
            promote_radius: location_params[:promote_radius].to_i,
            base_locations: [Location.find_by_slug_or_id(location_params[:location_id])]
        end
      end
  end
end
