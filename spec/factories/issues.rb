# == Schema Information
#
# Table name: issues
#
#  id                 :integer          not null, primary key
#  issue_edition      :string(255)
#  organization_id    :integer
#  copyright          :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  import_location_id :integer
#  publication_date   :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :issue do
    issue_edition "MyString"
    publication_date Time.current
    organization
    copyright "MyString"
  end
end
