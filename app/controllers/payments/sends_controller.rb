# frozen_string_literal: true

class Payments::SendsController < ApplicationController
  def create
    authorize! :manage, Payment
    period_start = Date.parse(params[:period_start])
    period_end = Date.parse(params[:period_end])
    SendPaymentsJob.perform_later(params[:period_start], params[:period_end])
    flash[:notice] = "Queued SendPaymentsJob for #{period_start} - #{period_end}"
    redirect_to payments_path
  end
end
