# frozen_string_literal: true

module Ugc
  class UpdateMarket
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
      @market_post = @content.channel

      @market_post.update market_post_params

      @market_post.content
    end

    private

    def market_post_params
      new_params = @params.dup
      attributes = additional_update_attributes
      new_params[:content] = new_params[:content].merge(attributes)

      new_params.require(:content).permit(
        :contact_email,
        :contact_phone,
        :contact_url,
        :cost,
        :latitude,
        :longitude,
        :locate_address,
        :locate_include_name,
        :locate_name,
        :status,
        :prefered_contact_method,
        :sold,
        content_attributes: %i[
          id
          title
          raw_content
          authoremail
          authors
          biz_feed_public
          content_category_id
          pubdate
          timestamp
          organization_id
          promote_radius
          sunset_date
          location_id
          url
        ]
      )
    end

    def additional_update_attributes
      {
        cost: @params[:content][:cost],
        content_attributes: {
          id: @params[:id],
          biz_feed_public: @params[:content][:biz_feed_public],
          title: @params[:content][:title],
          raw_content: @params[:content][:content],
          promote_radius: @params[:content].delete(:promote_radius),
          location_id: @params[:content][:location_id],
          url: @params[:content][:url]
        }
      }
    end
  end
end
