class PaymentRecipientsController < ApplicationController
  load_and_authorize_resource except: [:index]
  def index
    @payment_recipients = PaymentRecipient.all.includes(:user, :organization)
    @users = User.with_roles
    @recipient_user_ids = @payment_recipients.map(&:user_id)
  end

  def new
    @payment_recipient.user = User.find params[:user_id]
    @organizations = Organization.where("NOT EXISTS(SELECT * FROM payment_recipients WHERE payment_recipients.organization_id = organizations.id)")
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
    @organizations = Organization.where("NOT EXISTS(SELECT * FROM payment_recipients WHERE payment_recipients.organization_id = organizations.id) OR id = ?", @payment_recipient.organization_id)
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
      :user_id,
      :organization_id
    )
  end
end
