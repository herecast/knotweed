module Api
  module V3
    class OrganizationsController < ApiController
      load_and_authorize_resource only: [:show]

      def index
        if params[:organization_ids].present?
          if @requesting_app.present?
            @organizations = @requesting_app.organizations
          else
            @organizations = Organization
          end
          @organizations = @organizations.where(id: params[:organization_ids])
        else
          opts = {}
          opts = { select: '*, weight()' }
          opts[:with] = {}
          opts[:conditions] = {}
          opts[:page] = params[:page] || 1
          opts[:star] = true

          if @requesting_app.present?
            opts[:with][:consumer_app_ids] = @requesting_app.id
          end

          # only use organizations associated with news content
          news_cat = ContentCategory.find_by_name 'news'
          opts[:with][:content_category_ids] = news_cat.id

          query = Riddle::Query.escape("#{params[:query]}")
          @organizations = Organization.search query, opts
        end

        render json: @organizations, each_serializer: OrganizationSerializer
      end

      def show
        # filter to ensure organization belong to the requesting app
        if @requesting_app.present? and !@requesting_app.organizations.include?(@organization)
          head :no_content
        else
          render json: @organization, serializer: OrganizationSerializer
        end
      end

    end
  end
end
