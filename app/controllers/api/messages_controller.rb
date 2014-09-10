class Api::MessagesController < Api::ApiController
  def index
    @messages = filter_active_record_relation_for_consumer_app(Message.active)
    
    if params[:messages].present?
      @messages = @messages.where(controller: params[:messages][:controller]) if params[:messages][:controller].present?
      @messages = @messages.where(action: params[:messages][:action]) if params[:messages][:action].present?
    end

    render json: @messages
  end
end
