# == Schema Information
#
# Table name: report_job_params
#
#  id                        :integer          not null, primary key
#  report_job_paramable_type :string
#  report_job_paramable_id   :integer
#  param_name                :string
#  param_value               :string
#  created_by                :integer
#  updated_by                :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  report_job_params_paramable_type_id  (report_job_paramable_type,report_job_paramable_id)
#

class ReportJobParam < ActiveRecord::Base
  include Auditable

  belongs_to :report_job_paramable, polymorphic: true
end
