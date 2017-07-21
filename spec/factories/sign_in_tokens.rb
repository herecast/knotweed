# == Schema Information
#
# Table name: sign_in_tokens
#
#  id         :integer          not null, primary key
#  token      :string           not null
#  user_id    :integer
#  created_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sign_in_token do
    user
    created_at { Time.current }
  end
end
