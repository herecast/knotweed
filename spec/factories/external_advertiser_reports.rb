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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :external_advertiser_report do
  end
end
