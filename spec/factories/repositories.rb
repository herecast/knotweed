# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :repository do
    name "Test Repo"
    dsp_endpoint "http://23.92.16.168:8080"
    sesame_endpoint "http://23.92.16.168:8081/openrdf-sesame/repositories/subtext"
  end
end
