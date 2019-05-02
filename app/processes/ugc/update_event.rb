# frozen_string_literal: true

module Ugc
  class UpdateEvent
    def self.call(*args)
      new(*args).call
    end

    def initialize(content, params, remote_ip: nil, user_scope:)
      @current_user = user_scope
      @params = params
      @remote_ip = remote_ip
      @content = content
    end

    def call
      @event = @content.channel

      schedules = @params[:content][:schedules].map { |s| Schedule.build_from_ux_for_event(s, @event.id) }
      @event.update_with_schedules(event_params, schedules)
      @event.content.update_attribute(:location_id, @event.closest_location.id)

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
          :id,
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
        id: @params[:id],
        raw_content: @params[:content][:content],
        title: @params[:content][:title],
        location_id: @params[:content][:location_id],
        promote_radius: @params[:content][:promote_radius],
        biz_feed_public: @params[:content][:biz_feed_public],
        sunset_date: @params[:content][:sunset_date],
        url: @params[:content][:url]
      }
    end
  end
end
