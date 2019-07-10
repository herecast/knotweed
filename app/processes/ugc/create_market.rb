# frozen_string_literal: true

module Ugc
  class CreateMarket
    def self.call(*args)
      new(*args).call
    end

    def initialize(params, remote_ip: nil, user_scope:)
      @current_user = user_scope
      @params = params
      @remote_ip = remote_ip
    end

    def call
      @market_post = MarketPost.new(market_post_params)
      @market_post.save

      conditionally_schedule_outreach_email

      @market_post.content
    end

    private

    def market_post_params
      new_params = @params.dup
      attributes = additional_create_attributes
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
          biz_feed_public
          authoremail
          authors
          content_category_id
          pubdate
          timestamp
          organization_id
          promote_radius
          sunset_date
          location_id
          created_by
          origin
          url
        ]
      )
    end

    def additional_create_attributes
      {
        cost: @params[:content][:cost],
        content_attributes: {
          title: @params[:content][:title],
          raw_content: @params[:content][:content],
          biz_feed_public: @params[:content][:biz_feed_public],
          authoremail: @current_user.try(:email),
          authors: @current_user.try(:name),
          content_category_id: market_category.id,
          pubdate: Time.zone.now,
          timestamp: Time.zone.now,
          organization_id: @params[:content][:organization_id] || default_org.id,
          location_id: @params[:content][:location_id],
          created_by: @current_user,
          origin: Content::UGC_ORIGIN,
          url: @params[:content][:url]
        }
      }
    end

    def market_category
      ContentCategory.find_or_create_by(name: 'market')
    end

    def default_org
      Organization.find_by(standard_ugc_org: true)
    end

    def conditionally_schedule_outreach_email
      if @current_user.contents.market_posts.count == 1
        BackgroundJob.perform_later('Outreach::CreateUserHookCampaign', 'call',
                                    user: @current_user,
                                    action: 'initial_market_post')
      end
    end
  end
end
