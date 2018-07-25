module PaymentReportService
  extend self

  AVAILABLE_REPORTS = ['blogger_read_payments', 'publisher_read_payments']

  # runs specified report and returns a payment hash that the report_job uses
  # to generate a payment object
  #
  # @param report [String] name of report to run
  # @param params [Hash] options for report
  # @return [Hash] payment details
  def run_report(report, params)
    raise ArgumentError, "Invalid report type" unless AVAILABLE_REPORTS.include? report

    self.send(report, params)
  end

  private

    # this is executed once per `report_job_recipient` and accepts the user_id associated
    # with that recipient as a parameter. It generates a payment hash for every Content
    # record belonging to that user (that had views during the period).
    def blogger_read_payments(params)
      required_params = [
        :start_date,
        :end_date,
        :period_ad_rev,
        :user_id
      ]
      validate_required_params!(params, required_params)

      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])

      period_total = period_total_impressions(start_date, end_date)
      ppi = pay_per_impression(params[:period_ad_rev], period_total)

      promotion_metrics = PromotionBannerMetric.for_payment_period(start_date, end_date).
        joins(content: [:organization, :created_by]).
        where('contents.created_by = ?', params[:user_id]).
        where('organizations.pay_for_content = true').
        select('content_id, COUNT(DISTINCT promotion_banner_metrics.id) as impressions').
        group(:content_id).order(:content_id)

      payments = []
      promotion_metrics.each do |cr|
        paid_impressions = cr.impressions
        payment = {
          period_start: start_date,
          period_end: end_date,
          paid_impressions: paid_impressions,
          total_payment: (paid_impressions * ppi).to_d.truncate(2),
          payment_date: Time.current,
          pay_per_impression: ppi,
          content_id: cr.content_id,
          paid_to: User.find(params[:user_id])
        }
        payments << payment
      end

      payments
    end

    # this report is very similar to blogger_read_payments but it's run for organizations
    # instead, determined by the passed param[:org_name].
    # It should also be noted that it checks for contents by the passed organization OR by
    # its parent, if it has a parent.
    def publisher_read_payments(params)
      required_params = [
        :start_date,
        :end_date,
        :period_ad_rev,
        :org_name,
        :user_id
      ]
      validate_required_params!(params, required_params)

      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])

      period_total = period_total_impressions(start_date, end_date)
      ppi = pay_per_impression(params[:period_ad_rev], period_total)

      promotion_metrics = PromotionBannerMetric.for_payment_period(start_date, end_date).
        joins(:content).
        joins('INNER JOIN organizations o ON contents.organization_id = o.id').
        where('o.pay_for_content = true').
        where('o.name = ? OR '\
                   '(SELECT name '\
                   'FROM organizations '\
                   'WHERE id = o.parent_id) = ?',
              params[:org_name], params[:org_name]).
        select('content_id, COUNT(DISTINCT promotion_banner_metrics.id) as impressions').
        group(:content_id).order(:content_id)

      payments = []
      promotion_metrics.each do |cr|
        paid_impressions = cr.impressions
        payment = {
          period_start: start_date,
          period_end: end_date,
          paid_impressions: paid_impressions,
          total_payment: (paid_impressions * ppi).to_d.truncate(2),
          payment_date: Time.current,
          pay_per_impression: ppi,
          content_id: cr.content_id,
          paid_to: User.find(params[:user_id])
        }
        payments << payment
      end
      payments
    end

    def period_total_impressions(start_date, end_date)
      PromotionBannerMetric.for_payment_period(start_date, end_date).count
    end

    def pay_per_impression(ad_rev, total_impressions)
      if total_impressions > 0
        (ad_rev.to_f / total_impressions).to_d.truncate(2)
      else
        0
      end
    end

    def validate_required_params!(params, required_params)
      missing_keys = required_params - params.keys.map(&:to_sym)
      unless missing_keys.empty?
        raise ArgumentError, "Not all required params passed; missing: #{missing_keys}"
      end
    end

end
