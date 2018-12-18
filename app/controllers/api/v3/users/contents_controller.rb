# frozen_string_literal: true

module Api
  module V3
    class Users::ContentsController < ApiController
      before_action :check_logged_in!

      def index
        authorize! :manage, User.find(params[:id])

        search_opts = ContentSearch.my_stuff_query(
          params: params
        )

        @contents = Content.search(query, search_opts)

        @feed_items = @contents.map do |content|
          FeedItem.new(content)
        end

        render json: FeedContentVanillaSerializer.call(
          records: @feed_items,
          opts: { context: { current_ability: current_ability } }
        ).merge(
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
        @contents.present? ? (@contents.total_entries / per_page.to_f).ceil : nil
      end

      def per_page
        params[:per_page] || 20
      end
    end
  end
end
