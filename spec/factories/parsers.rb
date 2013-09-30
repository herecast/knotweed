# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :parser do
    filename "parser.rb"
    organization
    name "My Parser"
  end
end
