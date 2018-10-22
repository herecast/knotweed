# == Schema Information
#
# Table name: ad_metrics
#
#  id         :bigint(8)        not null, primary key
#  campaign   :string
#  event_type :string
#  page_url   :string
#  content    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AdMetric < ActiveRecord::Base
end
