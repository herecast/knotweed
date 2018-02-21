module Ugc
  class CreateNews
    def self.call(*args)
      self.new(*args).call
    end

    def initialize(params, repository: nil, user_scope:)
      @current_user = user_scope
      @repository = repository
      @params = params
    end

    def call
      record
    end

    def record
      @record ||= Content.create news_params.merge(
          created_by: @current_user,
          content_category: news_category,
          origin: Content::UGC_ORIGIN
        )
    end

    protected
      def news_category
        ContentCategory.find_or_create_by(name: 'news')
      end

      def news_params
        transformed_params.require(:content).permit(
          :authors,
          :authors_is_created_by,
          :organization_id,
          :promote_base_location_id,
          :promote_radius,
          :pubdate,
          :raw_content,
          :subtitle,
          :title
        )
      end

      def transformed_params
        ActionController::Parameters.new(@params).tap do |h|
          h[:content][:raw_content] = h[:content].delete :content if h[:content].has_key? :content
          h[:content][:pubdate] = h[:content].delete :published_at if h[:content].has_key? :published_at
          author_name = h[:content].delete :author_name

          if author_name == @current_user.name # @content hasn't been persisted yet so has no created_by
            # which means the current user IS the author
            h[:content][:authors_is_created_by] = true
          end

          unless h[:content][:authors_is_created_by]
            h[:content][:authors_is_created_by] = false
            h[:content][:authors] = author_name
          end
        end
      end
  end
end
