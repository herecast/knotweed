# frozen_string_literal: true

module Api
  module V3
    class OrganizationsController < ApiController
      before_action :check_logged_in!, only: %i[create update]

      def create
        authorize! :create, Organization

        @organization = Organization.new(create_organization_params)
        if @organization.save
          provision_user_as_manager_and_blogger
          schedule_blogger_welcome_emails
          conditionally_create_business_profile
          update_business_location
          notify_via_slack
          render json: @organization, serializer: OrganizationSerializer,
                 status: 201
        else
          render json: { errors: @organization.errors }, status: :unprocessable_entity
        end
      end

      def update
        @organization = Organization.find(params[:id])
        authorize! :update, @organization

        if @organization.update(organization_params)
          conditionally_create_business_profile
          update_business_location
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
          @organizations = Organization.where(id: params[:ids])
        else
          @opts = {}
          @opts[:where] = {}
          @opts[:page] = params[:page] || 1
          @opts[:includes] = [:business_locations]

          manage_certified_orgs
          query = params[:query].blank? ? '*' : params[:query]

          @organizations = Organization.search query, @opts
        end

        render json: @organizations, each_serializer: OrganizationSerializer, context: { current_ability: current_ability }
      end

      def show
        @organization = Organization.not_archived.find(params[:id])
        render json: @organization, serializer: OrganizationSerializer, context: { current_ability: current_ability }
      end

      def sitemap_ids
        ids = Organization.where('id <> ?', Organization::LISTSERV_ORG_ID)\
                          .where("
                 (org_type IN (:publishers) AND can_publish_news = TRUE) OR
                 (org_type = 'Business' AND biz_feed_active = TRUE)
          ", publishers: %w[Blog Publisher Publication])\
                          .order('updated_at DESC')\
                          .limit(50_000)\
                          .pluck(:id)
        render json: {
          organization_ids: ids
        }
      end

      protected

      def organization_params
        params.require(:organization).permit(
          :name,
          :description,
          :background_image,
          :profile_image,
          :desktop_image,
          :twitter_handle,
          :contact_card_active,
          :description_card_active,
          :hours_card_active,
          :remote_background_image_url,
          :remote_profile_image_url,
          :special_link_url,
          :special_link_text,
          :calendar_view_first,
          :calendar_card_active,
          :remove_desktop_image,
          :website,
          organization_locations_attributes: %i[
            location_type
            location_id
          ]
        )
      end

      def create_organization_params
        params[:organization][:organization_locations_attributes] = [{
          location_type: 'base',
          location_id: Location.find_by(city: 'Hartford', state: 'VT').id
        }]

        organization_params.tap do |attrs|
          attrs[:can_publish_news] = true
          attrs[:org_type] = 'Blog'
        end
      end

      def provision_user_as_manager_and_blogger
        current_user.add_role(:manager, @organization)
        current_user.add_role(:blogger)
      end

      def business_location_params
        params.require(:organization).permit(
          :phone,
          :email,
          :address,
          :city,
          :state,
          :zip,
          hours: []
        ).tap do |attrs|
          unless params[:organization][:website].nil?
            attrs[:venue_url] = params[:organization][:website]
          end
        end
      end

      def add_custom_links
        @organization.update_attribute(:custom_links, params[:organization][:custom_links])
      end

      def conditionally_create_business_profile
        if @organization.business_locations.empty?
          CreateBusinessProfileRelationship.call(org_name: @organization.name)
        end
      end

      def update_business_location
        @organization.business_locations.first.update_attributes(business_location_params)
      end

      def manage_certified_orgs
        if params[:certified_storyteller] == 'true' && params[:certified_social] == 'true'
          @opts[:where][:or] = [[
            { certified_social: true },
            { certified_storyteller: true }
          ]]
          @opts[:order] = { name: :asc }
        elsif params[:certified_storyteller] == 'true'
          @opts[:where][:certified_storyteller] = true
          @opts[:order] = { name: :asc }
        elsif params[:certified_social] == 'true'
          @opts[:where][:certified_social] = true
          @opts[:order] = { name: :asc }
        else
          # only use organizations associated with news content
          news_cat = ContentCategory.find_by_name 'news'
          @opts[:where][:content_category_ids] = [news_cat.id]
        end
      end

      def schedule_blogger_welcome_emails
        BackgroundJob.perform_later('Outreach::CreateMailchimpSegmentForNewUser', 'call', current_user,
                                    schedule_blogger_emails: true,
                                    organization: @organization)
      end

      def notify_via_slack
        if Figaro.env.production_messaging_enabled == 'true'
          BackgroundJob.perform_later('SlackService', 'send_new_blogger_alert',
            user: current_user,
            organization: @organization
          )
        end
      end
    end
  end
end
