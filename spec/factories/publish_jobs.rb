# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :publish_job do
    frequency 0
    publish_method Content::EXPORT_TO_XML

    after(:build) do |pj|
      pj.query_params[:repository_id] = FactoryGirl.create(:repository).id
    end
  end
end
