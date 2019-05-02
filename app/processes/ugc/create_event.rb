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
      @event = Event.new(event_params)

      schedules = @params[:content][:schedules].map { |s| Schedule.build_from_ux_for_event(s) }
      @event.save_with_schedules(schedules)
      @event.content.update_attribute(:location_id, @event.closest_location.id)
      @event.content.set_event_latest_activity

      conditionally_contact_user_and_ad_team
      conditionally_schedule_outreach_email

      @event.content
    end

    private

    def event_params
      params = @params.dup
      params[:event] = params.delete(:content)
      params[:event][:content_attributes] = content_attributes
      params[:event][:venue_attributes] = params[:event][:venue]

      params.require(:event).permit(
        :cost,
        :cost_type,
        :contact_email,
        :contact_phone,
        :registration_deadline,
        :registration_url,
        :registration_phone,
        :registration_email,
        :venue_id,
        venue_attributes: [
          :address,
          :city,
          :name,
          :state,
          :status,
          :venue_url,
          :zip
        ],
        content_attributes: [
          :raw_content,
          :title,
          :location_id,
          :promote_radius,
          :biz_feed_public,
          :sunset_date,
          :url,
          :pubdate,
          :content_category_id,
          :authoremail,
          :authors,
          :created_by,
          :origin,
          images: [
            :caption,
            :credit,
            :image,
            :imageable_type,
            :imageable_id,
            :created_at,
            :updated_at,
            :source_url,
            :primary,
            :width,
            :height,
            :file_extension,
            :position
          ]
        ]
      )
    end

    def content_attributes
      {
        raw_content: @params[:content][:content],
        title: @params[:content][:title],
        location_id: @params[:content][:location_id],
        promote_radius: @params[:content][:promote_radius],
        biz_feed_public: @params[:content][:biz_feed_public],
        sunset_date: @params[:content][:sunset_date],
        url: @params[:content][:url],
        organization_id: organization_id,
        images: [@params[:content][:image]],
        pubdate: Time.zone.now,
        content_category_id: ContentCategory.find_or_create_by(name: 'event').id,
        authoremail: @current_user.try(:email),
        authors: @current_user.try(:name),
        created_by: @current_user,
        origin: Content::UGC_ORIGIN
      }
    end

    def organization_id
      if @params[:content][:organization_id].present?
        @params[:content][:organization_id]
      else
        Organization.find_by(standard_ugc_org: true).id
      end
    end

    def conditionally_contact_user_and_ad_team
      if @params[:content][:wants_to_advertise]
        AdMailer.event_advertising_user_contact(@current_user).deliver_later
        AdMailer.event_advertising_request(@current_user, @event).deliver_later
      end
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
