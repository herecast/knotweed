module Api
  module V2
    class EventInstancesController < ApiController

      def index
        @event_instances = EventInstance.limit(500).order('start_date ASC')
          .includes(event: [{content: :images}, :venue])

        if params[:date_start].present?
          start_date = Chronic.parse(params[:date_start]).beginning_of_day
          @event_instances = @event_instances.where('event_instances.start_date >= ?', start_date)
        end
        if params[:date_end].present?
          end_date = Chronic.parse(params[:date_end]).end_of_day
          if end_date == start_date
            end_date = start_date.end_of_day
          end
          @event_instances = @event_instances.where('event_instances.start_date <= ?', end_date)
        end

        if params[:category].present?
          # .to_s below just helps our tests run -- if it alreayd is a symbol, then the rest
          # of the line does nothing. But params will typically come in as strings, so we need
          # to convert them to symbols here.
          sym_cat = params[:category].to_s.downcase.gsub(' ', '_').to_sym
          if Event::EVENT_CATEGORIES.include?(sym_cat)
            @event_instances = @event_instances.joins(:event)
              .where('events.event_category = ? ', sym_cat)
          end
        end

        render json: @event_instances, root: 'events', meta: { total: EventInstance.count }
      end

      def show
        @event_instance = EventInstance.find(params[:id])
        render json: @event_instance, root: 'event', serializer: DetailedEventInstanceSerializer
      end

    end
  end
end
