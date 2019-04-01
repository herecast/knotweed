# frozen_string_literal: true

module Ugc
  class CreateEvent
    def self.call(*args)
      new(*args).call
    end

    def initialize(params, remote_ip: nil, user_scope:)
      @current_user = user_scope
      @params = params
      @remote_ip = remote_ip
    end

    def call
      image_data = @params[:content].delete :image

      org_id = if @params[:content][:organization_id].present?
                 @params[:content].delete :organization_id
               else
                 Organization.find_or_create_by(name: 'From DailyUV').id
               end

      schedule_data = @params[:content].delete :schedules
      schedules = schedule_data.map { |s| Schedule.build_from_ux_for_event(s) }

      event_hash = ActionController::Parameters.new(
        process_event_params(@params[:content])
      ).permit!

      @event = Event.new(event_hash)

      @event.content.organization_id = org_id
      @event.content.images = [Image.create(image: image_data)] if image_data.present?

      if @event.save_with_schedules(schedules)
        contact_user_and_ad_team if @params[:content][:wants_to_advertise]
      end

      @event.content.update_attribute(:location_id, @event.closest_location.id)

      conditionally_schedule_outreach_email
      @event.content.set_event_latest_activity

      @event.content
    end

    private

    # accepts incoming params hash and returns a sanitized (only specified attributes accepted)
    # and translated hash of event data
    def process_event_params(e)
      include_upper_valley = e[:extended_reach_enabled]
      # have to parse out event.content parameters into the appropriate place
      new_e = { content_attributes: {} }
      new_e[:content_attributes][:raw_content] = e[:content] if e.key? :content
      new_e[:content_attributes][:title] = e[:title] if e.key? :title
      new_e[:content_attributes][:location_id] = e[:location_id] if e.key? :location_id

      new_e[:content_attributes][:promote_radius] = e[:promote_radius] if e.key? :promote_radius
      new_e[:content_attributes][:biz_feed_public] = e[:biz_feed_public]
      new_e[:content_attributes][:sunset_date] = e[:sunset_date] if e.key? :sunset_date

      new_e[:cost] = e[:cost] if e.key? :cost
      new_e[:cost_type] = e[:cost_type]
      new_e[:contact_email] = e[:contact_email] if e.key? :contact_email
      new_e[:contact_phone] = e[:contact_phone] if e.key? :contact_phone
      new_e[:content_attributes][:url] = e[:url] if e.key? :url

      new_e[:registration_deadline] = e[:registration_deadline] if e.key? :registration_deadline
      new_e[:registration_url] = e[:registration_url] if e.key? :registration_url
      new_e[:registration_phone] = e[:registration_phone] if e.key? :registration_phone
      new_e[:registration_email] = e[:registration_email] if e.key? :registration_email

      if @event.present? && @event.id # event already exists and this is an update so we need to include
        # the content ID to avoid overwriting it
        new_e[:content_attributes][:id] = @event.content.id
      else
        # NOTE: these attributes are here because they can't change on update
        new_e[:content_attributes] = new_e[:content_attributes].merge(
          pubdate: Time.zone.now,
          content_category_id: ContentCategory.find_or_create_by(name: 'event').id,
          authoremail: @current_user.try(:email),
          authors: @current_user.try(:name),
          created_by: @current_user,
          origin: Content::UGC_ORIGIN
        )
      end

      if e[:venue_id].present?
        new_e[:venue_id] = e[:venue_id]
      elsif e[:venue].present?
        new_e[:venue_attributes] = e[:venue]
      end

      # translate params that have the wrong name
      new_e[:event_category] = e[:category].to_s.downcase.tr(' ', '_') if e.key? :category
      new_e[:event_category] = nil
      new_e
    end

    def contact_user_and_ad_team
      AdMailer.event_advertising_user_contact(@current_user).deliver_later
      AdMailer.event_advertising_request(@current_user, @event).deliver_later
    end

    def conditionally_schedule_outreach_email
      if @current_user.contents.events.count == 1
        BackgroundJob.perform_later('Outreach::CreateUserHookCampaign', 'call',
                                    user: @current_user,
                                    action: 'initial_event_post')
      end
    end
  end
end
