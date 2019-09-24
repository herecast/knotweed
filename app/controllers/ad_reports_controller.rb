class AdReportsController < ApplicationController
  def index
    authorize! :manage, Payment
    if params[:period_start].present? && params[:period_end].present?
      @period_start = Date.parse(params[:period_start])
      @period_end = Date.parse(params[:period_end])
      campaigns = Content.ad_campaigns_for_reports(@period_start, @period_end).where('ad_invoiced_amount IS NOT NULL')
      if campaigns.count > 25
        flash[:error] = 'For performance reasons, this can\'t run on more than 25 campaigns.'
        render 'index'
      end

      @ad_revenue = 0
      campaigns.each do |camp|
        @ad_revenue += Promotions::CalculateAdRevenue.call(camp, @period_start, @period_end)
      end
    end
    render 'index'
  end
end
