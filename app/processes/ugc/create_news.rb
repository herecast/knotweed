# frozen_string_literal: true

module Ugc
  class CreateNews
    def self.call(*args)
      new(*args).call
    end

    def initialize(params, user_scope:)
      @current_user = user_scope
      @params = params
    end

    def call
      @record = Content.create(news_params.merge(
                                 created_by: @current_user,
                                 content_category: news_category,
                                 origin: Content::UGC_ORIGIN
                               ))

      @record
    end

    protected

    def news_category
      ContentCategory.find_or_create_by(name: 'news')
    end

    def news_params
      transformed_params.require(:content).permit(
        :authors,
        :authors_is_created_by,
        :biz_feed_public,
        :organization_id,
        :promote_radius,
        :pubdate,
        :raw_content,
        :subtitle,
        :sunset_date,
        :title,
        :location_id
      )
    end

    def transformed_params
      @params.tap do |h|
        h[:content][:raw_content] = h[:content].delete :content if h[:content].key? :content
        h[:content][:pubdate] = h[:content].delete :published_at if h[:content].key? :published_at
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
