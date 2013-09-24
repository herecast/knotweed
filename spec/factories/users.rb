# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    name 'Test User'
    sequence(:email) {|n| "email#{n}@test.com" }
    password 'changeme'
    password_confirmation 'changeme'
    # required if the Devise Confirmable module is used
    confirmed_at Time.now

    factory :admin do
      name 'Test Admin'
      after(:create) do |user|
        user.add_role :admin
      end
    end

    factory :organization_admin do
      name 'Test Organization Admin'
      organization
    end

  end
end
