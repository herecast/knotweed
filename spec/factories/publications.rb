# == Schema Information
#
# Table name: publications
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  logo                  :string(255)
#  organization_id       :integer
#  website               :string(255)
#  publishing_frequency  :string(255)
#  notes                 :text
#  parent_id             :integer
#  category_override     :string(255)
#  tagline               :text
#  links                 :text
#  social_media          :text
#  general               :text
#  header                :text
#  pub_type              :string(255)
#  display_attributes    :boolean          default(FALSE)
#  reverse_publish_email :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :publication do
    sequence(:name) {|n| "My Publication #{n}" }
    organization
  end
end
