module Api
  module V3
    class FeedController < ApiController
      def index
        expires_in 1.minutes, public: true unless is_my_stuff_request?
        render json: { feed_items: [] }, status: :ok and return if is_my_stuff_request? && current_user.nil?

        @result_object = GatherFeedRecords.call(
          params: params,
          requesting_app: @requesting_app,
          current_user: current_user
        )

        render json: FeedContentVanillaSerializer.call(
          records: @result_object[:records],
          opts: { context: { current_ability: current_ability } }
        ).merge(
          meta: {
            total: @result_object[:total_entries],
            total_pages: total_pages
          }
        )
      end

      protected

        def is_my_stuff_request?
          ['me', 'my_stuff', 'mystuff'].include?(params[:radius].to_s.downcase)
        end

        def total_pages
          @result_object[:total_entries].present? ? (@result_object[:total_entries]/per_page.to_f).ceil : nil
        end

        def per_page
          params[:per_page] || 20
        end

    end
  end
end