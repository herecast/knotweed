# frozen_string_literal: true

module Ugc
  class UpdateNews
    def self.call(*args)
      new(*args).call
    end

    def initialize(content, params, user_scope:)
      @current_user = user_scope
      @params = params
      @content = content
    end

    def call
      transform_params
      validate
      @content.update news_params
      @content
    end

    private

    # @TODO Move this to either model validation, or another layer.
    # These validations lived in the news controller.
    # I'm hesitant to move them to the model without knowing why they
    # were in the controller vs model before.

    def validate
      # if it's already published, don't allow changing the pubdate (i.e. unpublishing or scheduling)
      if @content.pubdate.present? &&
         (@content.pubdate <= Time.zone.now) && news_params.key?(:pubdate) &&
         (::Chronic.parse(news_params[:pubdate]).to_i != @content.pubdate.to_i)

        raise ValidationError, "Can't unpublish already published news content"
      end

      # don't allow publishing or scheduling without an organization
      if news_params[:organization_id].blank? &&
         @content.organization.blank? &&
         news_params[:pubdate].present?

        raise ValidationError, 'Organization must be specified for news content'
      end
    end

    def news_params
      @params.require(:content).permit(
        :authors,
        :authors_is_created_by,
        :biz_feed_public,
        :organization_id,
        :promote_radius,
        :pubdate,
        :raw_content,
        :subtitle,
        :title,
        :sunset_date,
        :location_id,
        :url
      )
    end

    def transform_params
      @params.tap do |h|
        h[:content][:raw_content] = h[:content].delete :content if h[:content].key? :content
        h[:content][:pubdate] = h[:content].delete :published_at if h[:content].key? :published_at
        author_name = h[:content].delete :author_name

        h[:content][:authors_is_created_by] = true if @content.created_by.try(:name) == author_name

        unless h[:content][:authors_is_created_by]
          h[:content][:authors_is_created_by] = false
          h[:content][:authors] = author_name
        end
      end
    end
  end
end
