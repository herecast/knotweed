# frozen_string_literal: true

module Api
  module V3
    class BusinessProfilesController < ApiController
      MI_TO_KM = 1.60934

      before_action :check_logged_in!, only: %i[create update]

      def index
        expires_in 1.minutes, public: true
        query = params[:query].present? ? params[:query] : '*'
        page = params[:page] || 1
        per_page = params[:per_page] || 14
        opts = {
          page: page,
          per_page: per_page,
          where: {
            exists: true,
            archived: false
          }
        }

        # don't do any geodist related stuff if organization_id comes in
        unless params[:organization_id].present?
          @coords = if params[:lat].present? && params[:lng].present?
                      [params[:lat], params[:lng]]
                    else
                      # default to center of Upper Valley
                      Location.default_location.coordinates
                    end

          radius = params[:radius] || 50 # default 50 miles
          # convert to radians
          opts[:where][:location] = {
            near: @coords,
            within: "#{radius}mi"
          }
        end

        opts[:order] = sort_by
        opts[:order].unshift(_score: :desc) if query.present? && (query != '*')

        if params[:category_id].present?
          opts[:where][:category_ids] = { in: BusinessCategory.find(params[:category_id]).full_descendant_ids }
        end

        if params[:organization_id].present?
          opts[:where][:organization_id] = params[:organization_id]
        end

        @business_profiles = BusinessProfile.search(query, opts)

        render json: @business_profiles, each_serializer: BusinessProfileSerializer,
               root: 'businesses', context: { current_ability: current_ability, current_user: current_user }, meta: { total: @business_profiles.total_entries }
      end

      def show
        @business_profile = BusinessProfile.find(params[:id])
        render json: @business_profile, serializer: BusinessProfileSerializer,
               root: 'business', context: { current_ability: current_ability, current_user: current_user }
      end

      def create
        authorize! :create, BusinessProfile
        @business_profile = BusinessProfile.new(business_profile_params)
        ModerationMailer.send_business_for_moderation(@business_profile, current_user).deliver_now
        # for Ember data to not get upset, we need to assign fake IDs to all the objects here
        @business_profile.content.id = Time.current.to_i
        @business_profile.organization.id = Time.current.to_i
        render json: @business_profile, serializer: BusinessProfileSerializer,
               status: 201, root: 'business', context: { current_ability: current_ability, current_user: current_user }
      end

      def update
        @business_profile = BusinessProfile.find(params[:id])
        # This may change (this endpoint can be leveraged, at some point, to be the
        # mechanism for "claiming?"), but as of now, you cannot #update
        # business profiles that haven't been claimed.
        if @business_profile.claimed?
          authorize! :update, @business_profile
          if @business_profile.update_attributes(business_profile_params)
            render json: @business_profile, serializer: BusinessProfileSerializer,
                   root: 'business', context: { current_ability: current_ability, current_user: current_user }
          else
            render json: { errors: @business_profile.errors.messages },
                   status: :unprocessable_entity
          end
        else
          render json: { errors: ["Business has not been claimed and can't be updated."] },
                 status: 422
        end
      end

      protected

      def sort_by
        order = params[:sort_by] || 'score_desc'
        case order
        when 'distance_asc'
          closest_order
        when 'score_desc'
          best_score_order
        when 'rated_desc'
          most_rated_order
        when 'alpha_asc'
          alpha_order
        when 'alpha_desc'
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

      def business_profile_params
        new_params = params
        new_params = new_params.merge(additional_attributes)
        new_params.delete(:business)
        new_params.require(:business_profile).permit(
          :has_retail_location,
          business_category_ids: [],
          content_attributes: [
            :id,
            :title,
            :raw_content,
            organization_attributes: %i[id description]
          ],
          business_location_attributes: [
            :id,
            :name,
            :phone,
            :email,
            :address,
            :city,
            :state,
            :zip,
            :status,
            :service_radius,
            :venue_url,
            :locate_include_name,
            hours: []
          ]
        )
      end

      def additional_attributes
        attributes = {
          business_profile: {
            has_retail_location: params[:business][:has_retail_location],
            business_category_ids: params[:business][:category_ids],
            content_attributes: {
              title: params[:business][:name],
              raw_content: params[:business][:details],
              organization_attributes: {
                description: params[:business][:details]
              }
            },
            business_location_attributes: params[:business].slice(
              :name, :phone, :email, :address, :city, :state, :zip, :hours, :service_radius
            ).merge(venue_url: params[:business][:website])
          }
        }

        if @business_profile.present?
          attributes[:business_profile][:content_attributes][:id] = @business_profile.try(:content).try(:id)
          attributes[:business_profile][:content_attributes][:organization_attributes][:id] = @business_profile.try(:content).try(:organization).try(:id)
          attributes[:business_profile][:business_location_attributes][:id] = @business_profile.try(:business_location).try(:id)
        end

        attributes
      end
    end
  end
end
