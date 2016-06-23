# == Schema Information
#
# Table name: organizations
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  logo                  :string(255)
#  organization_id       :integer
#  website               :string(255)
#  notes                 :text(65535)
#  parent_id             :integer
#  category_override     :string(255)
#  org_type              :string(255)
#  display_attributes    :boolean          default(FALSE)
#  reverse_publish_email :string(255)
#  can_reverse_publish   :boolean          default(FALSE)
#  can_publish_news      :boolean          default(FALSE)
#  subscribe_url         :string(255)
#  description           :text(65535)
#  profile_title         :string(255)
#  banner_ad_override    :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization do
    sequence(:name) {|n| "My Organization #{n}" }
    sequence(:reverse_publish_email) {|n| "reverse-publish-#{n}@subtext.org" }
  end
end
