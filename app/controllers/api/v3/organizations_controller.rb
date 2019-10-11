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
          create_or_update_business_location
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
          create_or_update_business_location
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
          opts = { load: false, where: { id: params[:ids] } }
          @organizations = Organization.search('*', opts)
        else
          @opts = { load: false }
          @opts[:where] = {}
          @opts[:page] = params[:page] || 1
          @opts[:includes] = [:business_locations]

          manage_certified_orgs
          query = params[:query].blank? ? '*' : params[:query]

          @organizations = Organization.search(query, @opts)
        end

        render json: organizations_with_context, status: :ok
      end

      def show
        organization = Organization.search_by(id: params[:id], user: current_user)
        if organization.present?
          render json: { organization: organization }, status: :ok
        else
          render json: {}, status: :not_found
        end
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
          attrs[:user_id] = current_user.id
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

      def create_or_update_business_location
        if @organization.business_locations.empty?
          @organization.business_locations.create(business_location_params)
        else
          @organization.business_locations.first.update_attributes(business_location_params)
        end
      end

      def add_custom_links
        @organization.update_attribute(:custom_links, params[:organization][:custom_links])
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
          @opts[:where][:content_categories] = ['news']
        end
      end

      def organizations_with_context
        @organizations.map do |organization_json|
          serialized_organization(organization_json)
        end
      end

      def serialized_organization(organization_json)
        organization_json.tap do |attrs|
          attrs['can_edit'] = current_user&.can_manage_organization?(organization_json['id']) || false
          attrs.each do |key, value|
            attrs.delete(key) if key[0] == '_'
          end
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
                                      organization: @organization)
        end
      end
    end
  end
end
