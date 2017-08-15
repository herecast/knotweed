module Api
  module V3
    class Organizations::ContentsController < ApiController

      def index
        expires_in 1.minutes, public: true

        organization = Organization.find(params[:organization_id])

        opts = {}
        opts[:order] = { pubdate: :desc }
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 12

        if organization.business_locations.present?
          business_location_ids = organization.business_locations.pluck(:id)
          event_ids = Event.where(venue_id: business_location_ids).pluck(:id)
        else
          event_ids = []
        end

        org_tagged_content_ids = organization.tagged_contents.pluck(:id)

        organization_search = { organization_id: organization.id }
        opts[:where] = {}
        opts[:where][:pubdate] = { lt: Time.current }
        opts[:where][:_or] = [
          { channel_type: 'MarketPost' }.merge(organization_search),
          { channel_type: 'Event' }.merge(organization_search),
          { root_content_category_id: ContentCategory.find_by_name('talk_of_the_town').id }.merge(organization_search),
          { root_content_category_id: ContentCategory.find_by_name('news').id }.merge(organization_search),
          { root_content_category_id: ContentCategory.find_by_name('campaign').id }.merge(organization_search),
          { channel_id: event_ids, channel_type: 'Event' },
          { id: org_tagged_content_ids }
        ]

        if params[:location_id].present?
          opts[:where][:all_loc_ids] = params[:location_id].to_i
        end

        @contents = Content.search('*', opts)

        render json: @contents, each_serializer: ContentSerializer, meta: { total: @contents.total_entries }
      end

      def update
        @content = Content.find(params[:content_id])
        if @content.update_attributes(content_params)
          render json: @content, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      private

        def content_params
          params.require(:content).permit(:biz_feed_public, :sunset_date)
        end

    end
  end
end

