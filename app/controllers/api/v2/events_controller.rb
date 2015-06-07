module Api
  module V2
    class EventsController < ApiController

      before_filter :check_logged_in!, only: [:create, :moderate, :update]

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
              render json: @event, status: 200
            else
              render json: { errors: map_error_keys(@event.errors.messages) }, status: :unprocessable_entity
            end
          else
            # listservs for reverse publishing -- not included in process_event_params!
            # because update doesn't include listserv publishing
            listservs = params[:event].delete :listserv_ids

            process_event_params!
            
            if @event.update_attributes(params[:event])
              # reverse publish to specified listservs
              if listservs.present?
                listservs.each do |d|
                  next unless d.present?
                  list = Listserv.find(d.to_i)
                  PromotionListserv.create_from_content(@event.content, list) if list.present? and list.active
                end
              end

              if @repository.present?
                @event.content.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
              end

              render json: @event, status: 200
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
        
        process_event_params!

        @event = Event.new(params[:event])
        @event.content.publication = pub
        @event.content.images = [Image.create(image: image_data)] if image_data.present?
        if @event.save
          # reverse publish to specified listservs
          if listservs.present?
            listservs.each do |d|
              next unless d.present?
              list = Listserv.find(d.to_i)
              PromotionListserv.create_from_content(@event.content, list) if list.present? and list.active
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
        render json: @event
      end

      def moderate
        event = Event.find(params[:id])

        ModerationMailer.send_moderation_flag_v2(event.content, params[:flag_type], @current_api_user).deliver
        head :no_content
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

      def process_event_params!
        include_upper_valley = params[:event].delete :extended_reach_enabled
        location_ids = [@current_api_user.try(:location_id)]
        location_ids.push Location::REGION_LOCATION_ID if include_upper_valley
        # have to parse out event.content parameters into the appropriate place
        params[:event][:content_attributes] = {
          raw_content: params[:event].delete(:content),
          title: params[:event].delete(:title),
          location_ids: location_ids,
          authoremail: @current_api_user.try(:email),
          authors: @current_api_user.try(:name),
          pubdate: Time.zone.now,
          content_category_id: ContentCategory.find_or_create_by_name('event').id,
        }
        if @event.present? and @event.id # event already exists and this is an update so we need to include
          #the content ID to avoid overwriting it
          params[:event][:content_attributes][:id] = @event.content.id
        end

        if params[:event][:venue].present? and !params[:event][:venue_id].present?
          params[:event][:venue_attributes] = params[:event].delete :venue
        end

        # translate params that have the wrong name
        params[:event][:event_category] = params[:event].delete(:category).to_s.downcase.gsub(' ','_')
        params[:event][:event_instances_attributes] = params[:event].delete :event_instances
        if params[:event][:event_instances_attributes].present?
          params[:event][:event_instances_attributes].map! do |ei|
            process_ei_params(ei)
          end
        end
      end

      # converts the actual model keys that active record labels errors with
      # to the keys used by our vendor application...kind of sucks but it is what it is.
      def map_error_keys(errors)
        errors[:category] = errors.delete :event_category
        errors[:event_instances] = errors.delete :event_instances_attributes
      end


    end
  end
end
