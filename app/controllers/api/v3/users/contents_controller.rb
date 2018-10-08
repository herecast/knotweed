module Api
  module V3
    class Users::ContentsController < ApiController
      before_action :confirm_correct_user

      def index
        search_opts = ContentSearch.my_stuff_query({
          params: params
        })

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

        def confirm_correct_user
          unless @current_user.present? && params[:id].to_i == @current_user.id
            render json: {}, status: :forbidden
          end
        end

        def query
          params[:query].present? ? params[:query] : '*'
        end

        def total_pages
          @contents.present? ? (@contents.total_entries/per_page.to_f).ceil : nil
        end

        def per_page
          params[:per_page] || 20
        end

    end
  end
end
