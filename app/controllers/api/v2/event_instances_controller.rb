module Api
  module V2
    class EventInstancesController < ApiController

      def index
        #if params[:query].present? or params[:location].present?
        query = Riddle::Query.escape("#{params[:query]} #{params[:location]}")

        opts = {}
        opts = { select: '*, weight()' }
        opts[:order] = 'start_date ASC'
        opts[:per_page] = params[:max_results] || 1000
        opts[:with] = {}
        opts[:conditions] = {}
        opts[:sql] = { include: {event: [{content: :images}, :venue]}}

        start_date = Chronic.parse(params[:date_start]) if params[:date_start].present?
        end_date = Chronic.parse(params[:date_end]) if params[:date_end].present?

        if start_date.present?
          if end_date.present?
            opts[:with].merge!({ start_date: start_date..end_date })
          else
            opts[:with].merge!({ start_date: start_date..60.days.from_now })
          end
        elsif end_date.present?
          opts[:with].merge!({ start_date: Time.now..end_date })
        end

        if params[:category].present?
          cat = params[:category].to_s.downcase.gsub(' ', '_')
          if Event::EVENT_CATEGORIES.include?(cat.to_sym)
            # NOTE: this conditional also handles the scenario where we are passed 'everything'
            # because 'everything' just means don't filter by category, and since 'everything'
            # is not inside that constant, we're good.
            opts[:conditions].merge!({ event_category: cat })
          end
        end

        @event_instances = EventInstance.search query, opts

        #@event_instances = EventInstance.limit(500).order('start_date ASC')
        #  .includes(event: [{content: :images}, :venue])

#        if params[:date_start].present?
#          start_date = Chronic.parse(params[:date_start]).beginning_of_day
#          @event_instances = @event_instances.where('event_instances.start_date >= ?', start_date)
#        end
#        if params[:date_end].present?
#          end_date = Chronic.parse(params[:date_end]).end_of_day
#          if end_date == start_date
#            end_date = start_date.end_of_day
#          end
#          @event_instances = @event_instances.where('event_instances.start_date <= ?', end_date)
#        end
#
#        if params[:category].present?
#          # .to_s below just helps our tests run -- if it alreayd is a symbol, then the rest
#          # of the line does nothing. But params will typically come in as strings, so we need
#          # to convert them to symbols here.
#          sym_cat = params[:category].to_s.downcase.gsub(' ', '_').to_sym
#          if Event::EVENT_CATEGORIES.include?(sym_cat)
#            @event_instances = @event_instances.joins(:event)
#              .where('events.event_category = ? ', sym_cat)
#          elsif sym_cat == :everything
#            # return everything...which we already do if they don't specify a category.
#            # so nothing needs to happen here.
#          end
#        end
#
        render json: @event_instances, root: 'events', meta: { total: EventInstance.count }
      end

      def show
        @event_instance = EventInstance.find(params[:id])
        render json: @event_instance, root: 'event', serializer: DetailedEventInstanceSerializer
      end

    end
  end
end
