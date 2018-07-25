class PaymentsController < ApplicationController
  def index
    authorize! :manage, Payment
    respond_to do |format|
      format.html { @payment_data = get_payment_data }
      format.csv { send_data(get_payment_csv, filename: "pending-payments-#{Date.today}.csv") }
    end
  end

  def destroy
    authorize! :manage, Payment
    period_start = Date.parse(params[:period_start])
    period_end = Date.parse(params[:period_end])
    if Payment.unpaid.where(period_start: period_start, period_end: period_end).destroy_all
      flash[:notice] = "Canceled payments for #{period_start.strftime("%D")} - #{period_end.strftime("%D")}"
    else
      flash[:error] = "There was an issue canceling payments."
    end
    redirect_to payments_path
  end

  private

  def get_payment_data
    payments = Payment.unpaid.includes(:paid_to, content: [:organization]).order('contents.title ASC')
    payment_data = {}

    # organizing payments for display in a table like this:
    # {
    #   "06/01/2018 - 06/30/2018" => {
    #     :total_impressions => 123,
    #     :total_payments => 12345,
    #     :users => {
    #       "User's Name" => {
    #         :id => 1,
    #         :organizations => {
    #           "Organization Name" => {
    #             :id => 1,
    #             :payments => [<Payment>]
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
    payments.each do |p|
      period = "#{p.period_start.strftime("%m/%d/%Y")} - #{p.period_end.strftime("%m/%d/%Y")}"
      payment_data[period] ||= { total_impressions: 0, total_payments: 0, users: {} }
      payment_data[period][:total_payments] += p.total_payment

      if p.paid_to.present?
        payment_data[period][:users][p.paid_to.fullname] ||= { total_payment: 0, total_impressions: 0, organizations: {}, id: p.paid_to.id }
        if p.content.organization.present?
          payment_data[period][:users][p.paid_to.fullname][:organizations][p.content.organization.name] ||= { id: p.content.organization.id, payments: [] }
          payment_data[period][:users][p.paid_to.fullname][:organizations][p.content.organization.name][:payments] << p
          payment_data[period][:users][p.paid_to.fullname][:total_payment] += p.total_payment
          payment_data[period][:users][p.paid_to.fullname][:total_impressions] += p.paid_impressions
        end
      end
    end

    # period level "total impressions" is required to show total impressions of ALL CONTENT
    # not just paid content over that period so we set it separately
    payment_data.keys.each do |period|
      p_dates = period.split(' - ').map{ |pd| Date.parse(pd) }
      payment_data[period][:total_impressions] = PromotionBannerMetric.for_payment_period(p_dates[0], p_dates[1]).count
    end
    payment_data
  end

  def get_payment_csv
    Payment.unpaid.by_user.to_csv
  end
end
