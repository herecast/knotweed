module Ugc
  class CreateTalk
    def self.call(*args)
      self.new(*args).call
    end

    def initialize(params, remote_ip: nil, repository: nil, user_scope:)
      @current_user = user_scope
      @repository = repository
      @params = params
      @remote_ip = remote_ip
    end

    def call
      @talk = Comment.new(talk_params.deep_merge(
        content_attributes: {
          created_by: @current_user,
          origin: Content::UGC_ORIGIN
        }
      ))

      manage_location_attributes @talk

      @talk.save

      @talk.content
    end

    protected
      def talk_category
        ContentCategory.find_or_create_by(name: 'talk_of_the_town')
      end

      def talk_params
        new_params = ActionController::Parameters.new(
          content: @params[:content].to_h
        )
        new_params[:content].merge!(additional_attributes)
        new_params[:content].delete(:promote_radius)
        new_params[:content].delete(:ugc_base_location_id)
        new_params.require(:content).permit(
          content_attributes: [
            :title,
            :authoremail,
            :authors,
            :raw_content,
            :pubdate,
            :organization_id,
            :content_category_id,
            :ugc_job
          ]
        )
      end

      def additional_attributes
        {
          content_attributes: {
            title: @params[:content][:title],
            authoremail: @current_api_user.try(:email),
            authors: @current_api_user.try(:name),
            raw_content: @params[:content][:content],
            pubdate: Time.zone.now,
            organization_id: @params[:content][:organization_id] || Organization.find_or_create_by(name: 'From DailyUV').id,
            content_category_id: talk_category.id,
            promote_radius: @params[:content][:promote_radius],
            ugc_job: @params[:content][:ugc_job]
          }
        }
      end

      def location_params
        @params[:content].slice(:promote_radius, :ugc_base_location_id)
      end

      def manage_location_attributes talk
        if location_params[:promote_radius].present? &&
            location_params[:ugc_base_location_id].present?

          UpdateContentLocations.call talk.content,
            promote_radius: location_params[:promote_radius].to_i,
            base_locations: [Location.find_by_slug_or_id(location_params[:ugc_base_location_id])]
        end
      end
  end
end