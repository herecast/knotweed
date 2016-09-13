# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listserv_digest do
    listserv
    listserv_content_ids []
    campaign_id "MyString"
    sent_at "2016-06-23 16:04:47"
  end
end
