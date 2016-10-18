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
#  unsubscribe_email           :string
#  post_email                  :string
#  subscribe_email             :string
#  mc_list_id                  :string
#  mc_group_name               :string
#  send_digest                 :boolean          default(FALSE)
#  last_digest_send_time       :datetime
#  last_digest_generation_time :datetime
#  digest_header               :text
#  digest_footer               :text
#  digest_reply_to             :string
#  timezone                    :string           default("Eastern Time (US & Canada)")
#  digest_description          :text
#  digest_send_day             :string
#  banner_ad_override_id       :integer
#  digest_query                :text
#  template                    :string
#  sponsored_by                :string
#  digest_subject              :string
#  digest_preheader            :string
#  display_subscribe           :boolean          default(FALSE)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listserv do
    name "My Listserv"
    active true
    digest_send_time '09:15'

    factory :vc_listserv do
      sequence(:reverse_publish_email) { |n| "mylistserv#{n}@vclab.net" }
      list_type 'external_list'
    end

    factory :subtext_listserv do
      sequence(:post_email) { |n| "posting-#{n}@subtext.org" }
      sequence(:subscribe_email) { |n| "subscribe-#{n}@subtext.org" }
      sequence(:unsubscribe_email) { |n| "unsubscribe-#{n}@subtext.org" }
      sequence(:digest_reply_to) { |n| "reply-#{n}@subtext.org" }
      list_type 'internal_list'
    end
    list_type 'custom_digest'
  end
end
