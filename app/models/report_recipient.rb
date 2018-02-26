# == Schema Information
#
# Table name: report_recipients
#
#  id                 :integer          not null, primary key
#  report_id          :integer
#  user_id            :integer
#  alternative_emails :string
#  created_by         :integer
#  updated_by         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class ReportRecipient < ActiveRecord::Base
  include Auditable

  belongs_to :user
  belongs_to :report
end
