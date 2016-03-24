module Api
  module V3
    class BusinessProfilesController < ApiController

      MI_TO_KM = 1.60934

      before_filter :check_logged_in!, :parse_params!, only: [:create, :update]

      def index
        page = params[:page] || 1
        per_page = params[:per_page] || 14
        opts = { 
          select: '*, weight()', 
          page: page, 
          per_page: per_page, 
          star: true,
          with: {} 
        }

        if params[:lat].present? and params[:lng].present?
          lat = params[:lat]
          lng = params[:lng]
        else # default to center of Upper Valley
          lat,lng = Location::DEFAULT_LOCATION_COORDS
        end

        # convert to radians
        opts[:geo] = [lat,lng].map{ |coord| coord.to_f * Math::PI / 180 }
        radius = params[:radius] || 15 # default 15 miles
        # sphinx takes meters, but assumption is we are dealing with miles,
        # so need to convert
        opts[:with][:geodist] = 0.0..(radius.to_f*MI_TO_KM*1000)
        opts[:order] = "geodist ASC"
        
        if params[:category_id].present?
          opts[:with][:category_ids] = [params[:category_id]]
        end

        @business_profiles = BusinessProfile.search(params[:query], opts)
        render json: @business_profiles, each_serializer: BusinessProfileSerializer,
          root: 'businesses', context: {current_ability: current_ability}
      end

      def show
        @business_profile = Content.find(params[:id]).channel
        render json: @business_profile, serializer: BusinessProfileSerializer,
          root: 'business', context: {current_ability: current_ability}
      end

      def create
        @business_profile = BusinessProfile.new(params[:business])
        ModerationMailer.send_business_for_moderation(@business_profile, @current_api_user).deliver
        # for Ember data to not get upset, we need to assign fake IDs to all the objects here
        @business_profile.content.id = Time.now.to_i
        @business_profile.organization.id = Time.now.to_i
        render json: @business_profile, serializer: BusinessProfileSerializer,
          status: 201, root: 'business'
        #if @business_profile.save
        #  render json: @business_profile, serializer: BusinessProfileSerializer,
        #    status: 201, root: 'business'
        #else
        #  render json: { errors: @business_profile.errors.messages },
        #    status: :unprocessable_entity
        #end
      end

      def update
        @business_profile = Content.find(params[:id]).channel
        # need to add IDs to nested model updates
        params[:business][:content_attributes][:id] = @business_profile.content.id
        params[:business][:content_attributes][:organization_attributes][:id] = @business_profile.organization.id
        params[:business][:business_location_attributes][:id] = @business_profile.business_location_id
        if @business_profile.update_attributes(params[:business])
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
        params[:business][:content_attributes] = { organization_attributes: {} }
        params[:business][:business_location_attributes] = {}

        # :name attribute is reflected in both the content and organization record,
        # so copy it here before deleting.
        params[:business][:content_attributes][:title] = params[:business][:name] if params[:business].has_key? :name

        [:name, :website].each do |attr|
          if params[:business].has_key? attr
            params[:business][:content_attributes][:organization_attributes][attr] = params[:business].delete attr
          end
        end
        
        params[:business][:content_attributes][:raw_content] = params[:business].delete :details if params[:business].has_key? :details

        [:phone, :email, :address, :city, :state, :zip, :hours, :service_radius].each do |attr|
          if params[:business].has_key? attr
            params[:business][:business_location_attributes][attr] = params[:business].delete attr
          end
        end

        params[:business][:business_category_ids] = params[:business].delete :category_ids
      end

    end
  end
end
