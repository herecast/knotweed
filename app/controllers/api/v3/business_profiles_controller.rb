module Api
  module V3
    class BusinessProfilesController < ApiController

      before_filter :check_logged_in!, :parse_params!, only: [:create, :update]

      def index
        page = params[:page] || 1
        per_page = params[:per_page] || 14
        if params[:query].present?
          opts = { select: '*, weight()', page: page, per_page: per_page }
          @business_profiles = BusinessProfile.search(params[:query], opts)
        else
          @business_profiles = BusinessProfile.page(page).per(per_page)
        end
        render json: @business_profiles, each_serializer: BusinessProfileSerializer,
          root: 'businesses'
      end

      def show
        @business_profile = Content.find(params[:id]).channel
        render json: @business_profile, serializer: BusinessProfileSerializer,
          root: 'business'
      end

      def create
        @business_profile = BusinessProfile.new(params[:business_profile])
        if @business_profile.save
          render json: @business_profile, serializer: BusinessProfileSerializer,
            status: 201, root: 'business'
        else
          render json: { errors: @business_profile.errors.messages },
            status: :unprocessable_entity
        end
      end

      def update
        @business_profile = Content.find(params[:id]).channel
        # need to add IDs to nested model updates
        params[:business_profile][:content_attributes][:id] = @business_profile.content.id
        params[:business_profile][:content_attributes][:organization_attributes][:id] = @business_profile.organization.id
        params[:business_profile][:business_location_attributes][:id] = @business_profile.business_location_id
        if @business_profile.update_attributes(params[:business_profile])
          render json: @business_profile, serializer: BusinessProfileSerializer,
            status: 204
        else
          render json: { errors: @business_profile.errors.messages },
            status: :unprocessable_entity
        end
      end

      protected

      # this method takes incoming API parameters and scopes them according to the
      # nested resource to which they belong.
      def parse_params!
        params[:business_profile][:content_attributes] = { organization_attributes: {} }
        params[:business_profile][:business_location_attributes] = {}

        # :name attribute is reflected in both the content and organization record,
        # so copy it here before deleting.
        params[:business_profile][:content_attributes][:title] = params[:business_profile][:name] if params[:business_profile].has_key? :name

        [:name, :website].each do |attr|
          if params[:business_profile].has_key? attr
            params[:business_profile][:content_attributes][:organization_attributes][attr] = params[:business_profile].delete attr
          end
        end
        
        params[:business_profile][:content_attributes][:raw_content] = params[:business_profile].delete :details if params[:business_profile].has_key? :details

        [:phone, :email, :address, :city, :state, :zip, :hours].each do |attr|
          if params[:business_profile].has_key? attr
            params[:business_profile][:business_location_attributes][attr] = params[:business_profile].delete attr
          end
        end

        # type is a reserved keyword so backend is biz_type
        params[:business_profile][:biz_type] = params[:business_profile].delete :type if params[:business_profile].has_key? :type

        params[:business_profile].delete :categories
      end

      
    end
  end
end
