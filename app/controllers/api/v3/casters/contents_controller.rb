# frozen_string_literal: true

module Api
  module V3
    class Casters::ContentsController < ApiController

      def index
        if params[:commented] == 'true'
          search_opts = ContentSearch.comment_query(
            params: params,
            current_user: current_user
          )
        elsif params[:caster_feed] == 'true'
          search_opts = ContentSearch.caster_follows_query(
            params: params.merge(caster: true),
            current_user: current_user
          )
        else
          search_opts = ContentSearch.caster_query(
            params: params.merge(caster: true)
          )
        end

        @contents = Content.search(query, search_opts)

        @feed_items = @contents.map do |content|
          FeedItem.new(content)
        end

        render json: FeedContentVanillaSerializer.call(@feed_items).merge(
          meta: {
            total: @contents.total_entries,
            total_pages: total_pages
          }
        )
      end

      private

      def query
        params[:query].present? ? params[:query] : '*'
      end

      def total_pages
        @contents.present? ? (@contents.total_entries / per_page.to_f).ceil : 0
      end

      def per_page
        params[:per_page] || 20
      end
    end
  end
end
