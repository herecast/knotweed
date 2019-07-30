# frozen_string_literal: true

# == Schema Information
#
# Table name: listservs
#
#  id                          :bigint(8)        not null, primary key
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
#  digest_query                :text
#  template                    :string
#  sponsored_by                :string
#  display_subscribe           :boolean          default(FALSE)
#  digest_subject              :string
#  digest_preheader            :string
#  list_type                   :string           default("custom_list")
#  sender_name                 :string
#  promotion_ids               :integer          default([]), is an Array
#  admin_email                 :string
#  forwarding_email            :string
#  forward_for_processing      :boolean          default(FALSE)
#  post_threshold              :integer          default(0)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listserv do
    name 'My Listserv'
    active true
    digest_send_time '09:15'
    digest_send_day 'Monday'
  end
end
