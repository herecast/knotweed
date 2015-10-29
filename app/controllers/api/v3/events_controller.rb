module Api
  module V3
    class EventsController < ApiController

      before_filter :check_logged_in!, only: [:create, :update]
      after_filter :track_create, only: :create

      def update
        @event = Event.find(params[:id])
        # "authenticate" this edit action
        if @current_api_user.email != @event.content.authoremail
          render json: { errors: ['You do not have permission to edit this event.'] }, 
            status: 401
        else
          # for now, we EITHER get the image OR the event in this update logic. So 
          # if image is present here, we branch:
          image_data = params[:event].delete :image
          if image_data.present?
            # clear out existing images since we are only set up to have one right now
            @event.content.images.destroy_all
            if Image.create(image: image_data, imageable: @event.content)
              render json: @event, serializer: EventSerializer, status: 200
            else
              render json: { errors: map_error_keys(@event.errors.messages) }, status: :unprocessable_entity
            end
          else
            listservs = params[:event].delete :listserv_ids

            event_hash = process_event_params(params[:event])
            
            if @event.update_attributes(event_hash)
              # reverse publish to specified listservs
              if listservs.present?
                listservs.each do |d|
                  next unless d.present?
                  list = Listserv.find(d.to_i)
                  PromotionListserv.create_from_content(@event.content, list, @requesting_app) if list.present? and list.active
                end
              end

              if @repository.present?
                @event.content.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
              end

              render json: @event, serializer: EventSerializer,  status: 200
            else
              render json: {
                errors: map_error_keys(@event.errors.messages)
              }, status: :unprocessable_entity
            end
          end
        end
      end

      def create
        image_data = params[:event].delete :image

        # listservs for reverse publishing -- not included in process_event_params!
        # because update doesn't include listserv publishing
        listservs = params[:event].delete :listserv_ids

        # hard coded publication...
        pub = Publication.find_or_create_by_name 'DailyUV'
        
        event_hash = process_event_params(params[:event])

        @event = Event.new(event_hash)
        @event.content.publication = pub
        @event.content.images = [Image.create(image: image_data)] if image_data.present?
        if @event.save
          # reverse publish to specified listservs
          if listservs.present?
            listservs.each do |d|
              next unless d.present?
              list = Listserv.find(d.to_i)
              PromotionListserv.create_from_content(@event.content, list, @requesting_app) if list.present? and list.active
            end
          end

          if @repository.present?
            @event.content.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
          end

          render json: @event, status: 201
        else
          render json: {
            errors: map_error_keys(@event.errors.messages)
          }, status: :unprocessable_entity
        end
      end

      def show
        @event = Event.find(params[:id])
        if @requesting_app.present?
          head :no_content and return unless @requesting_app.try(:publications).try(:include?, @event.publication)
        end
        render json: @event, serializer: EventSerializer
      end

      protected
      # this is an unfortunate consequence of the fact that our ember app is using different keys
      # for certain things than we are...
      def process_ei_params(ei)
        new_ei = {}
        new_ei[:id] = ei[:id] if ei[:id].present? # for updating
        new_ei[:subtitle_override] = ei[:subtitle] if ei[:subtitle].present?
        new_ei[:start_date] = ei[:starts_at] if ei[:starts_at].present?
        new_ei[:end_date] = ei[:ends_at] if ei[:ends_at].present?
        new_ei
      end

      # accepts incoming params hash and returns a sanitized (only specified attributes accepted)
      # and translated hash of event data
      def process_event_params(e)
        include_upper_valley = e[:extended_reach_enabled]
        location_ids = [@current_api_user.try(:location_id)]
        location_ids.push Location::REGION_LOCATION_ID if include_upper_valley
        # have to parse out event.content parameters into the appropriate place
        new_e = { content_attributes: {} }
        new_e[:content_attributes][:raw_content] = e[:content] if e[:content].present?
        new_e[:content_attributes][:title] = e[:title] if e[:title].present?
        new_e[:content_attributes][:location_ids] = location_ids.uniq

        new_e[:cost] = e[:cost] if e[:cost].present?
        new_e[:cost_type] = e[:cost_type] if e[:cost_type].present?
        new_e[:contact_email] = e[:contact_email] if e[:contact_email].present?
        new_e[:contact_phone] = e[:contact_phone] if e[:contact_phone].present?
        new_e[:event_url] = e[:event_url] if e[:event_url].present?

        if @event.present? and @event.id # event already exists and this is an update so we need to include
          #the content ID to avoid overwriting it
          new_e[:content_attributes][:id] = @event.content.id
        else
          new_e[:content_attributes][:pubdate] = Time.zone.now
          # NOTE: these attributes are here because they can't change on update
          new_e[:content_attributes].merge!({
            pubdate: Time.zone.now,
            content_category_id: ContentCategory.find_or_create_by_name('event').id,
            authoremail: @current_api_user.try(:email),
            authors: @current_api_user.try(:name)
          })
        end

        if e[:venue_id].present?
          new_e[:venue_id] = e[:venue_id]
        elsif e[:venue].present?
          new_e[:venue_attributes] = e[:venue]
        end

        # translate params that have the wrong name
        new_e[:event_category] = e[:category].to_s.downcase.gsub(' ','_')
        new_e[:event_instances_attributes] = e[:event_instances]
        if new_e[:event_instances_attributes].present?
          new_e[:event_instances_attributes].map! do |ei|
            process_ei_params(ei)
          end
        end
        new_e
      end

      # converts the actual model keys that active record labels errors with
      # to the keys used by our vendor application...kind of sucks but it is what it is.
      def map_error_keys(errors)
        errors[:category] = errors.delete :event_category
        errors[:event_instances] = errors.delete :event_instances_attributes
      end

      private

      def track_create
        props = {}
        props.merge! @tracker.navigation_properties('Event', 'event.create', url_for, params)
        props.merge! @tracker.content_properties(@event.content)
        props.merge! @tracker.content_creation_properties('create', nil)
        @tracker.track(@mixpanel_distinct_id, 'submitContent', @current_api_user, props)
      end

    end
  end
end
