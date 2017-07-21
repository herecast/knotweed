# == Schema Information
#
# Table name: listserv_content_metrics
#
#  id                   :integer          not null, primary key
#  listserv_content_id  :integer
#  email                :string
#  time_sent            :datetime
#  post_type            :string
#  username             :string
#  verified             :boolean
#  enhanced             :boolean
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  enhance_link_clicked :boolean          default(FALSE)
#  step_reached         :string
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listserv_content_metric do
    listserv_content_id 1
  end
end
