module Ugc
  class UpdateNews
    def self.call(*args)
      self.new(*args).call
    end

    def initialize(content, params, user_scope:)
      @current_user = user_scope
      @params = params
      @content = content
    end

    def call
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
        if @content.pubdate.present? and
            @content.pubdate <= Time.zone.now and news_params.has_key?(:pubdate) and
            ::Chronic.parse(news_params[:pubdate]).to_i != @content.pubdate.to_i

          raise ValidationError.new("Can't unpublish already published news content")
        end

        # don't allow publishing or scheduling without an organization
        if news_params[:organization_id].blank? and
            @content.organization.blank? and
            news_params[:pubdate].present?

          raise ValidationError.new("Organization must be specified for news content")
        end
      end

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
          :title,
          :sunset_date,
          :location_id
        )
      end

      def transformed_params
        ActionController::Parameters.new(@params).tap do |h|
          h[:content][:raw_content] = h[:content].delete :content if h[:content].has_key? :content
          h[:content][:pubdate] = h[:content].delete :published_at if h[:content].has_key? :published_at
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
