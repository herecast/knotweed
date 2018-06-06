module Ugc
  class UpdateEvent
    def self.call(*args)
      self.new(*args).call
    end

    def initialize(content, params, remote_ip: nil, user_scope:)
      @current_user = user_scope
      @params = params
      @remote_ip = remote_ip
      @content = content
    end

    def call
      @event = @content.channel

      @params[:content].delete :image

      schedule_data = @params[:content].delete :schedules
      schedules = schedule_data.map{ |s| Schedule.build_from_ux_for_event(s, @event.id) }

      event_hash = ActionController::Parameters.new(
        process_event_params(@params[:content])
      ).permit!

      update_locations @event

      @event.update_with_schedules(event_hash, schedules)
      return @event.content
    end

    private
      # accepts incoming params hash and returns a sanitized (only specified attributes accepted)
      # and translated hash of event data
      def process_event_params(e)
        include_upper_valley = e[:extended_reach_enabled]
        # have to parse out event.content parameters into the appropriate place
        new_e = { content_attributes: {} }
        new_e[:content_attributes][:raw_content] = e[:content] if e.has_key? :content
        new_e[:content_attributes][:title] = e[:title] if e.has_key? :title
        new_e[:content_attributes][:ugc_job] = e[:ugc_job] if e.has_key? :ugc_job

        new_e[:content_attributes][:promote_radius] = e[:promote_radius] if e.has_key? :promote_radius

        new_e[:content_attributes][:biz_feed_public] = e[:biz_feed_public]

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
            authoremail: @current_user.try(:email),
            authors: @current_user.try(:name)
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

      def location_params
        @params[:content].slice(:promote_radius, :location_id)
      end

      def update_locations model
        if location_params[:promote_radius].present? &&
            location_params[:location_id].present?

          UpdateContentLocations.call model.content,
            promote_radius: location_params[:promote_radius].to_i,
            base_locations: [Location.find_by_slug_or_id(location_params[:location_id])]
        end
      end
  end
end
