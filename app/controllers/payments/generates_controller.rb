# frozen_string_literal: true

class Payments::GeneratesController < ApplicationController
  def create
    authorize! :manage, Payment
    period_start = Date.parse(params[:period_start])
    period_end = Date.parse(params[:period_end])
    GeneratePaymentsJob.perform_later(params[:period_start], params[:period_end], params[:period_ad_rev])
    flash[:notice] = "Queued GeneratePaymentsJob for #{period_start} - #{period_end}"
    redirect_to payments_path
  end

  def new
    authorize! :manage, Payment
  end
end
