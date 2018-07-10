# == Schema Information
#
# Table name: sign_in_tokens
#
#  id         :integer          not null, primary key
#  token      :string           not null
#  user_id    :integer
#  created_at :datetime         not null
#
# Indexes
#
#  index_sign_in_tokens_on_token    (token)
#  index_sign_in_tokens_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_a9860dd74e  (user_id => users.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sign_in_token do
    user
    created_at { Time.current }
  end
end
