module Api
  module V3
    class Users::CommentsController < ApiController
      before_action :confirm_correct_user

      def index
        search_opts = ContentSearch.comment_query({
          params: params,
          requesting_app: @requesting_app
        })

        @contents = Content.search(query, search_opts)
        opts = { context: { current_ability: current_ability } }

        render json: {
          comments: @contents.map do |c|
            HashieMashes::ContentSerializer.new(c, opts).as_json['content']
          end
        }.merge(
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
