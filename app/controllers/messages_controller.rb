class MessagesController < ApplicationController
  load_and_authorize_resource

  def index
  end

  def new
  end

  def create
    @message.created_by = current_user
    if @message.save
      flash[:notice] = "Message saved."
      redirect_to messages_path
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    @message = Message.find(params[:id])
    if @message.update_attributes(message_params)
      flash[:notice] = "Message updated."
      redirect_to messages_path
    else
      render 'edit'
    end
  end

  def destroy
  end

  private

    def message_params
      params.require(:message).permit(
        :action,
        :content,
        :controller,
        :created_by,
        :end_date,
        :start_date,
        consumer_app_ids: []
      )
    end

end
