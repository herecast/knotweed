module DashboardHelper
  def yesterday_signed_in_percentage(metrics)
    val = ((metrics[:sign_ins][:yesterday] / metrics[:total_users].to_f) * 100).to_i
  end
end
