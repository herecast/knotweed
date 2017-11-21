module Api
  module V3
    class OrganizationsController < ApiController
      load_resource only: [:show]

      before_filter :check_logged_in!, only: [:update]

      def update
        @organization = Organization.find(params[:id])
        authorize! :update, @organization

        if @organization.update organization_params
          add_custom_links if params[:organization].key?(:custom_links)
          render json: @organization, serializer: OrganizationSerializer,
            status: 204
        else
          render json: { errors: @organization.errors.messages },
            status: :unprocessable_entity
        end
      end

      def index
        expires_in 1.minute, public: true
        if params[:ids].present?
          if @requesting_app.present?
            @organizations = @requesting_app.organizations
          else
            @organizations = Organization
          end
          @organizations = @organizations.where(id: params[:ids])
        else
          opts = {}
          opts[:where] = {}
          opts[:page] = params[:page] || 1
          opts[:includes] = [:business_locations]

          if @requesting_app.present?
            opts[:where][:consumer_app_ids] = [@requesting_app.id]
          end

          if params[:subtext_certified] == "true"
            opts[:where][:subtext_certified] = 1
          else
            # only use organizations associated with news content
            news_cat = ContentCategory.find_by_name 'news'
            opts[:where][:content_category_ids] = [news_cat.id]
          end

          query = params[:query].blank? ? '*' : params[:query]

          @organizations = Organization.search query, opts
        end

        render json: @organizations, each_serializer: OrganizationSerializer, context: { current_ability: current_ability }
      end

      def show
        # filter to ensure organization belong to the requesting app
        if @requesting_app.present? and !@requesting_app.organizations.include?(@organization)
          head :no_content
        else
          render json: @organization, serializer: OrganizationSerializer, context: { current_ability: current_ability }
        end
      end

      protected

      def organization_params
        params.require(:organization).permit(
          :name,
          :profile_title,
          :description,
          :subscribe_url,
          :logo,
          :background_image,
          :profile_image,
          :twitter_handle
        )
      end

      def add_custom_links
        @organization.update_attribute(:custom_links, params[:organization][:custom_links])
      end

    end
  end
end
