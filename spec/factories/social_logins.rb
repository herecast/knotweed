# == Schema Information
#
# Table name: social_logins
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  provider   :string           not null
#  uid        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  extra_info :json
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :social_login do
  end
end
