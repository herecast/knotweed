module Api
  module V3
    class EventsController < ApiController

      before_filter :check_logged_in!, only: [:create, :update]

      def index
        expires_in 1.minutes, :public => true

        opts = {}
        opts[:order] = { pubdate: :desc }
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 5
        opts[:where] = {}
        opts[:where][:published] = 1 if @repository.present?
        opts[:where][:channel_type] = 'Event'
        opts[:sql] = { include: [:images, :organization, :root_content_category] }

        if @requesting_app.present?
          allowed_orgs = @requesting_app.organizations
          opts[:where][:organization_id] = allowed_orgs.collect{|c| c.id}
        end

        if params[:location_id].present?
          opts[:where][:all_loc_ids] = [Location.find_by_slug_or_id(params[:location_id]).id]
        else
          @default_location_id = Location.find_by_city(Location::DEFAULT_LOCATION).id
          opts[:where][:all_loc_ids] = [@default_location_id]
        end

        query = params[:query].present? ? params[:query] : '*'
        @events = Content.search query, opts

        render json: @events, each_serializer: ContentSerializer
      end

      def update
        @event = Event.find(params[:id])
        # "authenticate" this edit action
        authorize! :update, @event.content
        # for now, we EITHER get the image OR the event in this update logic. So
        # if image is present here, we branch:
        image_data = params[:event].delete :image
        if image_data.present?
          # clear out existing images since we are only set up to have one right now
          @event.content.images.destroy_all
          if Image.create(image: image_data, imageable: @event.content)
            render json: @event, serializer: EventSerializer, status: 200, context: { current_ability: current_ability }
          else
            head :unprocessable_entity
          end
        else
          listserv_ids = params[:event].delete(:listserv_ids) || []

          schedule_data = params[:event].delete :schedules
          schedules = schedule_data.map{ |s| Schedule.build_from_ux_for_event(s, @event.id) }
          event_hash = process_event_params(params[:event])

          if @event.update_with_schedules(event_hash, schedules)
            if listserv_ids.present?
              # reverse publish to specified listservs
              PromoteContentToListservs.call(
                @event.content,
                @requesting_app,
                request.remote_ip,
                *Listserv.where(id: listserv_ids.flatten)
              )
            end

            if @repository.present?
              PublishContentJob.perform_later(@event.content, @repository, Content::DEFAULT_PUBLISH_METHOD)
            end

            render json: @event, serializer: EventSerializer,  status: 200, context: { current_ability: current_ability }
          else
            render json: {
              errors: @event.errors.messages
            }, status: :unprocessable_entity
          end
        end
      end

      def create
        image_data = params[:event].delete :image

        # listservs for reverse publishing -- not included in process_event_params!
        # because update doesn't include listserv publishing
        listserv_ids = params[:event].delete(:listserv_ids) || []

        if params[:event][:organization_id].present?
          org_id = params[:event].delete :organization_id
        else
          org_id = Organization.find_or_create_by(name: 'From DailyUV').id
        end

        schedule_data = params[:event].delete :schedules
        schedules = schedule_data.map{ |s| Schedule.build_from_ux_for_event(s) }

        event_hash = process_event_params(params[:event])

        @event = Event.new(event_hash)
        @event.content.organization_id = org_id
        @event.content.images = [Image.create(image: image_data)] if image_data.present?
        if @event.save_with_schedules(schedules)
          contact_user_and_ad_team if params[:event][:wants_to_advertise]

          # reverse publish to specified listservs
          if listserv_ids.present?
            # reverse publish to specified listservs
            PromoteContentToListservs.call(
              @event.content,
              @requesting_app,
              request.remote_ip,
              *Listserv.where(id: listserv_ids)
            )
          end

          if @repository.present?
            PublishContentJob.perform_later(@event.content, @repository, Content::DEFAULT_PUBLISH_METHOD)
          end

          render json: @event, status: 201, serializer: EventSerializer, context: { current_ability: current_ability }
        else
          render json: {
            errors: @event.errors.messages
          }, status: :unprocessable_entity
        end
      end

      def show
        @event = Event.find(params[:id])
        if @requesting_app.present? and !@requesting_app.organizations.include?(@event.content.organization)
          head :no_content
        else
          render json: @event, serializer: EventSerializer, context: { current_ability: current_ability }
        end
      end

      protected

      # accepts incoming params hash and returns a sanitized (only specified attributes accepted)
      # and translated hash of event data
      def process_event_params(e)
        include_upper_valley = e[:extended_reach_enabled]
        location_ids = [@current_api_user.try(:location_id)]
        location_ids.push Location::REGION_LOCATION_ID if include_upper_valley
        # have to parse out event.content parameters into the appropriate place
        new_e = { content_attributes: {} }
        new_e[:content_attributes][:raw_content] = e[:content] if e.has_key? :content
        new_e[:content_attributes][:title] = e[:title] if e.has_key? :title
        new_e[:content_attributes][:location_ids] = location_ids.uniq

        new_e[:cost] = e[:cost] if e.has_key? :cost
        new_e[:cost_type] = e[:cost_type]
        new_e[:contact_email] = e[:contact_email] if e.has_key? :contact_email
        new_e[:contact_phone] = e[:contact_phone] if e.has_key? :contact_phone
        new_e[:event_url] = e[:event_url] if e.has_key? :event_url

        new_e[:registration_deadline] = e[:registration_deadline] if e.has_key? :registration_deadline
        new_e[:registration_url] = e[:registration_url] if e.has_key? :registration_url
        new_e[:registration_phone] = e[:registration_phone] if e.has_key? :registration_phone
        new_e[:registration_email] = e[:registration_email] if e.has_key? :registration_email

        if @event.present? and @event.id # event already exists and this is an update so we need to include
          #the content ID to avoid overwriting it
          new_e[:content_attributes][:id] = @event.content.id
        else
          new_e[:content_attributes][:pubdate] = Time.zone.now
          # NOTE: these attributes are here because they can't change on update
          new_e[:content_attributes].merge!({
            pubdate: Time.zone.now,
            content_category_id: ContentCategory.find_or_create_by(name: 'event').id,
            authoremail: @current_api_user.try(:email),
            authors: @current_api_user.try(:name)
          })
        end

        if e[:venue_id].present?
          new_e[:venue_id] = e[:venue_id]
        elsif e[:venue].present?
          new_e[:venue_attributes] = e[:venue].to_hash
        end

        # translate params that have the wrong name
        new_e[:event_category] = e[:category].to_s.downcase.gsub(' ','_') if e.has_key? :category
        new_e[:event_category] = nil
        new_e
      end

      def contact_user_and_ad_team
        AdMailer.event_advertising_user_contact(@current_api_user).deliver_later
        AdMailer.event_adveritising_request(@current_api_user, @event).deliver_later
      end

    end
  end
end
