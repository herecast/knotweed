# frozen_string_literal: true

class PaymentRecipientsController < ApplicationController
  load_and_authorize_resource except: [:index]
  def index
    @payment_recipients = PaymentRecipient.all.includes(:user)
    @recipient_user_ids = @payment_recipients.map(&:user_id)
  end

  def new
    @payment_recipient.user = User.find params[:user_id]
    render partial: 'payment_recipients/partials/form', layout: false
  end

  def create
    if @payment_recipient.save
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js { render json: @payment_recipient.errors }
      end
    end
  end

  def edit
    render partial: 'payment_recipients/partials/form', layout: false
  end

  def update
    if @payment_recipient.update_attributes(payment_recipient_params)
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js { render json: @payment_recipient.errors }
      end
    end
  end

  def destroy
    if @payment_recipient.destroy
      respond_to { |format| format.js }
    else
      respond_to { |format| format.js { render json: @payment_recipient.errors } }
    end
  end

  private

  def payment_recipient_params
    params.require(:payment_recipient).permit(
      :user_id
    )
  end
end
