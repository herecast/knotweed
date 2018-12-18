# frozen_string_literal: true

module DashboardHelper
  def yesterday_signed_in_percentage(metrics)
    ((metrics[:sign_ins][:yesterday] / metrics[:total_users].to_f) * 100).to_i
  end
end
