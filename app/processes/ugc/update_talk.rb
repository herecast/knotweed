module Ugc
  class UpdateTalk
    def self.call(*args)
      self.new(*args).call
    end

    def initialize(content, params, remote_ip: nil, user_scope:)
      @current_user = user_scope
      @params = params
      @remote_ip = remote_ip
      @content = content
    end

    def call
      @content.update talk_update_params
      @content
    end

    protected
      def talk_update_params
        new_params = ActionController::Parameters.new(
          content: @params[:content]
        )
        new_params[:content][:raw_content] = new_params[:content].delete(:content)
        new_params.require(:content).permit(
          :title,
          :biz_feed_public,
          :raw_content,
          :promote_radius,
          :sunset_date
        )
      end

  end
end
