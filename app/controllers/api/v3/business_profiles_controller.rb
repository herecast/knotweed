module Api
  module V3
    class BusinessProfilesController < ApiController

      MI_TO_KM = 1.60934

      before_filter :check_logged_in!, only: [:create, :update]

      def index
        query = params[:query].present? ? params[:query] : '*'

        page = params[:page] || 1
        per_page = params[:per_page] || 14
        opts = {
          page: page,
          per_page: per_page,
          where: {
            exists: 1,
            archived: false
          }
        }

        # don't do any geodist related stuff if organization_id comes in
        unless params[:organization_id].present?
          if params[:lat].present? and params[:lng].present?
            @coords = [params[:lat], params[:lng]]
          else
            # default to center of Upper Valley
            @coords = Location::DEFAULT_LOCATION_COORDS
          end

          radius = params[:radius] || 50 # default 50 miles
          # convert to radians
          opts[:where][:location] = {
           near: @coords,
           within: "#{radius}mi"
          }
        end

        opts[:order] = sort_by

        if params[:category_id].present?
          opts[:where][:category_ids] = { in: BusinessCategory.find(params[:category_id]).full_descendant_ids }
        end

        if params[:organization_id].present?
          opts[:where][:organization_id] = params[:organization_id]
        end

        @business_profiles = BusinessProfile.search(query, opts)

        render json: @business_profiles, each_serializer: BusinessProfileSerializer,
          root: 'businesses', context: {current_ability: current_ability, current_user: current_user}, meta: {total: @business_profiles.total_entries}
      end

      def show
        @business_profile = BusinessProfile.find(params[:id])
        render json: @business_profile, serializer: BusinessProfileSerializer,
          root: 'business', context: {current_ability: current_ability, current_user: current_user}
      end

      def create
        @business_profile = BusinessProfile.new(business_profile_attributes)
        ModerationMailer.send_business_for_moderation(@business_profile, @current_api_user).deliver_now
        # for Ember data to not get upset, we need to assign fake IDs to all the objects here
        @business_profile.content.id = Time.current.to_i
        @business_profile.organization.id = Time.current.to_i
        render json: @business_profile, serializer: BusinessProfileSerializer,
          status: 201, root: 'business', context: {current_ability: current_ability, current_user: current_user}
        #if @business_profile.save
        #  render json: @business_profile, serializer: BusinessProfileSerializer,
        #    status: 201, root: 'business'
        #else
        #  render json: { errors: @business_profile.errors.messages },
        #    status: :unprocessable_entity
        #end
      end

      def update
        @business_profile = BusinessProfile.find(params[:id])
        # This may change (this endpoint can be leveraged, at some point, to be the
        # mechanism for "claiming?"), but as of now, you cannot #update
        # business profiles that haven't been claimed.
        if @business_profile.content.nil?
          render json: { errors: ["Business has not been claimed and can't be updated."] },
            status: 422
        else
          if @business_profile.update_attributes(business_profile_attributes)
            render json: @business_profile, serializer: BusinessProfileSerializer,
              root: 'business', context: {current_ability: current_ability, current_user: current_user}
          else
            render json: { errors: @business_profile.errors.messages },
              status: :unprocessable_entity
          end
        end
      end

      protected
      def sort_by
        order = params[:sort_by] || "score_desc"
        case order
          when "distance_asc"
            closest_order
          when "score_desc"
            best_score_order
          when "rated_desc"
            most_rated_order
          when "alpha_asc"
            alpha_order
          when "alpha_desc"
            [{ business_location_name: :desc }]
          else
            return []
        end
      end

      def best_score_order
        [
          { feedback_recommend_avg: :desc },
          { feedback_count: :desc },
          geodist_clause,
          { business_location_name: :asc }
        ]
      end
      
      def geodist_clause
        if @coords.present?
          {
            _geo_distance: {
              'location' => @coords.join(','),
              'order' => 'asc',
              'unit' => 'mi'
            }
          }
        else
          {}
        end
      end

      def closest_order
        [
          geodist_clause,
          { feedback_recommend_avg: :desc },
          { feedback_count: :desc },
          { business_location_name: :asc }
        ]
      end

      def most_rated_order
        [
          { feedback_count: :desc },
          { feedback_recommend_avg: :desc },
          geodist_clause,
          { business_location_name: :asc }
        ]
      end

      def alpha_order
        [
          { business_location_name: :asc },
          { feedback_recommend_avg: :desc },
          { feedback_count: :desc },
          geodist_clause
        ]
      end

      def business_params
        params.require(:business).permit(:name, :phone, :email, :website,
                                         :address, :city, :state, :zip,
                                         :has_retail_location, :service_radius,
                                         :details, category_ids: [], hours: [])
      end

      def content_attributes
        bp = business_params

        ca = {
          organization_attributes: organization_attributes
        }
        ca[:id] = @business_profile.try(:content).try(:id) if @business_profile
        ca[:title] = bp[:name] if bp[:name].present?
        ca[:raw_content] = bp[:details] if bp[:details].present?
        ca
      end

      def organization_attributes
        oa = {}
        oa[:id] = @business_profile.try(:content).try(:organization).try(:id) if @business_profile
        oa
      end

      def business_location_attributes
        bp = business_params

        bla = bp.slice(:name, :phone, :email, :address, :city, :state, :zip,
                       :hours, :service_radius)
        bla[:id] = @business_profile.try(:business_location).try(:id) if @business_profile
        bla[:venue_url] = bp[:website] if bp[:website].present?
        bla
      end

      def business_profile_attributes
        bp = business_params

        bpa = business_params.slice(
          :has_retail_location
        ).merge({
          content_attributes: content_attributes,
          business_location_attributes: business_location_attributes
        })
        bpa[:business_category_ids] = bp[:category_ids] if bp[:category_ids].present?

        bpa
      end
    end
  end
end
