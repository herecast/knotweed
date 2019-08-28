# == Schema Information
#
# Table name: external_advertiser_reports
#
#  id              :bigint(8)        not null, primary key
#  title           :string
#  pdf             :string
#  organization_id :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_external_advertiser_reports_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#

class ExternalAdvertiserReport < ApplicationRecord
  belongs_to :organization

  mount_uploader :pdf, FileUploader
end
