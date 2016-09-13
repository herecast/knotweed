# == Schema Information
#
# Table name: listservs
#
#  id                          :integer          not null, primary key
#  name                        :string(255)
#  reverse_publish_email       :string(255)
#  import_name                 :string(255)
#  active                      :boolean
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  digest_send_time            :time
#  unsubscribe_email           :string(255)
#  post_email                  :string(255)
#  subscribe_email             :string(255)
#  mc_list_id                  :string(255)
#  mc_segment_id               :string(255)
#  send_digest                 :boolean          default(FALSE)
#  last_digest_send_time       :datetime
#  last_digest_generation_time :datetime
#  digest_header               :text(65535)
#  digest_footer               :text(65535)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listserv do
    name "My Listserv"
    active true
    digest_send_time '09:15'

    factory :vc_listserv do
      sequence(:reverse_publish_email) { |n| "mylistserv#{n}@vclab.net" }
    end

    factory :subtext_listserv do
      sequence(:post_email) { |n| "posting-#{n}@subtext.org" }
      sequence(:subscribe_email) { |n| "subscribe-#{n}@subtext.org" }
      sequence(:unsubscribe_email) { |n| "unsubscribe-#{n}@subtext.org" }
      sequence(:digest_reply_to) { |n| "reply-#{n}@subtext.org" }
    end
  end
end
