# frozen_string_literal: true

module Api
  module V3
    class EventInstancesController < ApiController
      include EmailTemplateHelper

      def index
        opts = { load: false }
        opts[:order] = [
          { starts_at: :asc },
          { venue_name: :asc },
          { title: :asc }
        ]
        opts[:where] = {}
        opts[:where][:removed] = { not: true }
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 20

        apply_date_query opts
        apply_query_location_filters opts

        query = params[:query].present? ? params[:query] : '*'
        @event_instances = EventInstance.search(query, opts)

        total_pages = ((@event_instances.total_count || 100) / opts[:per_page].to_f).ceil
        render json: @event_instances, each_serializer: HashieMashes::DetailedEventInstanceSerializer,
               meta: {
                 count: @event_instances.count,
                 total: @event_instances.try(:total_count) || @event_instances.count,
                 total_pages: total_pages
               }
      end

      def show
        @event_instance = EventInstance.find(params[:id])
        if current_user.present?
          url = edit_content_url(@event_instance.event.content) if current_user.has_role? :admin
        end
        ical_url = url_for_consumer_app("/#{event_instances_ics_path(params[:id])}")

        if @event_instance.event.content.removed?
          update_event_instance_as_removed
        end

        if request.headers['HTTP_ACCEPT'] == 'text/calendar'
          render plain: @event_instance.to_ics
        else
          render json: @event_instance, root: 'event_instance', serializer: EventInstanceSerializer,
                 context: { current_ability: current_ability, admin_content_url: url, ical_url: ical_url }
        end
      end

      private

      def apply_date_query(opts)
        start_date = (params[:start_date].present? ? DateTime.parse(params[:start_date]) : DateTime.now)
        end_date = (params[:end_date].present? ? DateTime.parse(params[:end_date]) : nil)

        opts[:where][:starts_at] = if end_date.present?
                                     start_date.beginning_of_day..end_date.end_of_day
                                   else
                                     { gte: start_date }
                                   end
      end

      def apply_query_location_filters(opts)
        if location.present?
          opts[:where][:location_id] = { in: location.send(radius_method) }
        end
      end

      def update_event_instance_as_removed
        dupe = CreateAlternateContent.call(@event_instance.event.content)
        @event_instance.event.define_singleton_method(:content) { dupe }
        %i[venue contact_phone contact_email event_url].each do |sym|
          @event_instance.event.define_singleton_method(sym) { nil }
        end
      end

      def location
        current_user.present? ? current_user.location : Location.find_by(id: params[:location_id])
      end

      def radius
        params[:radius].presence || 'fifty'
      end

      def radius_method
        "location_ids_within_#{radius}_miles".to_sym
      end
    end
  end
end
