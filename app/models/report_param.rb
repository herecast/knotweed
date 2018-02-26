# == Schema Information
#
# Table name: report_params
#
#  id                :integer          not null, primary key
#  report_id         :integer
#  report_param_type :string
#  param_name        :string
#  param_value       :string
#  created_by        :integer
#  updated_by        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class ReportParam < ActiveRecord::Base
  include Auditable
  extend Enumerize

  belongs_to :report
  enumerize :report_param_type, in: [:report, :recipient]
end
