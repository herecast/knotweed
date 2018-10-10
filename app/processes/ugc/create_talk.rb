module Ugc
  class CreateTalk
    def self.call(*args)
      self.new(*args).call
    end

    def initialize(params, remote_ip: nil, user_scope:)
      @current_user = user_scope
      @params = params
      @remote_ip = remote_ip
    end

    def call
      @talk = Comment.new(talk_params.deep_merge(
        content_attributes: {
          created_by: @current_user,
          origin: Content::UGC_ORIGIN
        }
      ))

      @talk.save

      @talk.content
    end

    protected
      def talk_category
        ContentCategory.find_or_create_by(name: 'talk_of_the_town')
      end

      def talk_params
        new_params = ActionController::Parameters.new(
          content: @params[:content].to_h
        )
        new_params[:content].merge!(additional_attributes)
        new_params[:content].delete(:promote_radius)
        new_params.require(:content).permit(
          content_attributes: [
            :title,
            :authoremail,
            :authors,
            :biz_feed_public,
            :raw_content,
            :pubdate,
            :organization_id,
            :content_category_id,
            :sunset_date,
            :location_id
          ]
        )
      end

      def additional_attributes
        {
          content_attributes: {
            title: @params[:content][:title],
            authoremail: @current_user.try(:email),
            authors: @current_user.try(:name),
            biz_feed_public: @params[:content][:biz_feed_public],
            raw_content: @params[:content][:content],
            pubdate: Time.zone.now,
            organization_id: @params[:content][:organization_id] || Organization.find_or_create_by(name: 'From DailyUV').id,
            content_category_id: talk_category.id,
            promote_radius: @params[:content][:promote_radius],
            location_id: @params[:content][:location_id]
          }
        }
      end

  end
end
