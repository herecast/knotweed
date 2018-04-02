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
#  archived           :boolean          default(FALSE)
#
# Indexes
#
#  index_report_recipients_on_user_id_and_report_id  (user_id,report_id)
#

class ReportRecipient < ActiveRecord::Base
  include Auditable

  belongs_to :user
  belongs_to :report

  validates :user, uniqueness: { scope: :report }, presence: true
  validates :report, uniqueness: { scope: :user }, presence: true

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
end
