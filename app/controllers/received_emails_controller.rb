class ReceivedEmailsController < ApplicationController
  before_action :set_received_email, only: [:show]

  def index
    @received_emails = ReceivedEmail.order('created_at DESC').page(params[:page]).per(params[:per_page] || 100)
  end

  def show
  end

  private
  def set_received_email
    @received_email = ReceivedEmail.find(params[:id])
  end

end
