module Api
  module V2
    class EventsController < ApiController

      before_filter :check_logged_in!, only: [:create] 

      def create
        image_data = params[:event].delete :image
        include_upper_valley = params[:event].delete :extended_reach_enabled
        location_ids = [@current_api_user.try(:location_id)]
        location_ids.push Location::REGION_LOCATION_ID if include_upper_valley

        # have to parse out event.content parameters into the appropriate place
        params[:event][:content_attributes] = {
          raw_content: params[:event].delete(:content),
          title: params[:event].delete(:title),
          location_ids: location_ids,
          #image: params[:event].delete(:image),
          #created_by: params[:current_user_id]
        }

        if params[:event][:venue].present? and !params[:event][:venue_id].present?
          params[:event][:venue_attributes] = params[:event].delete :venue
        end

        # translate params that have the wrong name
        params[:event][:event_category] = params[:event].delete :category
        params[:event][:event_instances_attributes] = params[:event].delete :event_instances
        if params[:event][:event_instances_attributes].present?
          params[:event][:event_instances_attributes].each do |ei|
            process_ei_params!(ei)
          end
        end

        # listservs for reverse publishing
        listservs = params[:event].delete :listserv_ids
        
        @event = Event.new(params[:event])
        @event.content.image = image_data if image_data.present?
        if @event.save
          # reverse publish to specified listservs
          if listservs.present?
            listservs.each do |d|
              next unless d.present?
              list = Listserv.find(d.to_i)
              PromotionListserv.create_from_content(@event.content, list) if list.present? and list.active
            end
          end

          render json: @event.event_instances.first, status: 201
        else
          head :unprocessable_entity
        end
      end

      def show
        @event = Event.find(params[:id])
        render json: @event
      end

      protected
      # this is an unfortunate consequence of the fact that our ember app is using different keys
      # for certain things than we are...
      def process_ei_params!(ei)
        ei[:subtitle_override] = ei.delete(:subtitle) if ei[:subtitle].present?
        ei[:start_date] = ei.delete(:starts_at) if ei[:starts_at].present?
        ei[:end_date] = ei.delete(:ends_at) if ei[:ends_at].present?
      end

    end
  end
end
